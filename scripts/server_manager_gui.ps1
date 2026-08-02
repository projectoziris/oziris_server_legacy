# server_manager_gui.ps1 - OZI-RIS Server Pack GUI control panel
# PowerShell + WinForms wrapper around the existing scripts\*.cmd modules.
# Launches itself elevated when needed (Start/Stop/Restart require admin).
# Logs every action to logs\server_manager_gui.log

param(
    [switch]$SelfElevate = $false,
    [switch]$SmokeTest = $false
)

$ErrorActionPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------------------------------------------------------------- config
$script:Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$script:Cfg = @{}
Get-Content -LiteralPath (Join-Path $script:Root 'config\server.ini') | ForEach-Object {
    if ($_ -match '^\s*([^;#=\[]+)=(.*)$') { $script:Cfg[$matches[1].Trim()] = $matches[2].Trim() }
}
$script:Install = $script:Cfg['install_path']
$script:ApachePort = $script:Cfg['apache_port']
$script:MysqlPort  = $script:Cfg['mysql_port']
$script:LogDir     = Join-Path $script:Root 'logs'
if (-not (Test-Path -LiteralPath $script:LogDir)) { New-Item -ItemType Directory -Path $script:LogDir | Out-Null }

# ---------------------------------------------------------------- helpers
function Write-GuiLog([string]$msg) {
    Add-Content -LiteralPath (Join-Path $script:LogDir 'server_manager_gui.log') `
        -Value ("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg)
}

function Get-IsAdmin {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object System.Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Run a pack script (scripts\name.cmd) and stream its output to the GUI log box.
function Invoke-PackScript([string]$name, [string]$arg = '') {
    $scriptPath = Join-Path (Join-Path $script:Root 'scripts') $name
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        Add-Output "ERROR: $name not found"
        return 1
    }
    $tmp = Join-Path $env:TEMP ("ozi_$([guid]::NewGuid().ToString('N')).txt")
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'cmd.exe'
    $psi.Arguments = '/c ""' + $scriptPath + '" ' + $arg + ' > "' + $tmp + '" 2>&1"'
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardError = $true
    try {
        $proc = [System.Diagnostics.Process]::Start($psi)
        $proc.WaitForExit()
        $proc.Dispose()
    } catch {
        Add-Output ("ERROR running {0}: {1}" -f $name, $_.Exception.Message)
        return 1
    }
    if (Test-Path -LiteralPath $tmp) {
        Get-Content -LiteralPath $tmp | ForEach-Object { Add-Output $_ }
        Remove-Item -LiteralPath $tmp -Force
    }
    Write-GuiLog ("invoke {0} {1} -> exit {2}" -f $name, $arg, $proc.ExitCode)
    return $proc.ExitCode
}

# Add a line to the output text box (thread-safe).
function Add-Output([string]$text) {
    if ($script:OutputBox.InvokeRequired) {
        $script:OutputBox.Invoke([Action[string]]{ param($t) $script:OutputBox.AppendText($t + "`r`n") }, $text)
    } else {
        $script:OutputBox.AppendText($text + "`r`n")
    }
}

function Update-ServiceStatus {
    foreach ($name in @('Apache24','MariaDB')) {
        $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
        $box = if ($name -eq 'Apache24') { $script:LblApache } else { $script:LblMaria }
        $val = if ($svc) { "$($svc.Status)" } else { 'NOT INSTALLED' }
        $color = if ($svc -and $svc.Status -eq 'Running') { [System.Drawing.Color]::Green }
                elseif ($svc) { [System.Drawing.Color]::OrangeRed } else { [System.Drawing.Color]::Gray }
        if ($box.InvokeRequired) {
            $box.Invoke([Action]{ $box.Text = $val; $box.ForeColor = $color })
        } else {
            $box.Text = $val; $box.ForeColor = $color
        }
    }
}

function Refresh-ResourceMeters {
    $os = Get-CimInstance Win32_OperatingSystem
    $free = $os.FreePhysicalMemory; $total = $os.TotalVisibleMemorySize
    $ramPct = if ($total -gt 0) { [math]::Round(100 * ($total - $free) / $total, 0) } else { 0 }
    $cpu = (Get-CimInstance Win32_Processor | Measure-Object LoadPercentage -Average).Average
    [void]($script:BarCpu.Value = [int]($cpu * $script:BarCpu.Maximum / 100))
    [void]($script:BarRam.Value = [int]($ramPct * $script:BarRam.Maximum / 100))
    $script:LblCpu.Text = "CPU $([int]$cpu)%"
    $script:LblRam.Text = "RAM $ramPct% ($([math]::Round($free/1MB,1)) GB free)"
}

function Refresh-LogList {
    $script:LogList.Items.Clear()
    Get-ChildItem -LiteralPath $script:LogDir -Filter '*.log' | Sort-Object LastWriteTime -Descending |
        Select-Object -First 30 | ForEach-Object { [void]$script:LogList.Items.Add($_.Name) }
}

function Refresh-TaskToggle {
    $script:ChkStartup.Enabled = $false
    $t = Get-ScheduledTask -TaskName 'OZI-RIS Startup Safety Net' -ErrorAction SilentlyContinue
    $enabled = $false
    if ($t) {
        $enabled = $t.State -ne 'Disabled'
        if ($t.Settings) { $enabled = $t.Settings.Enabled }
    }
    $script:InitTaskToggle = $true
    [void]($script:ChkStartup.Checked = $enabled)
    $script:InitTaskToggle = $false
    $script:ChkStartup.Enabled = $true
}

# ---------------------------------------------------------------- async workers
# Simple async runner using Start-Job (child process, supports $using:).
# Streams job output to the output box and calls onDone when finished.
# NOTE: event-handler scriptblocks cannot see function-local variables, so
# job state is kept in $script:AsyncStore and the timer is reached via $this.
$script:AsyncStore = @{}
function Start-AsyncJob([scriptblock]$job, [scriptblock]$onDone) {
    $id = [guid]::NewGuid().ToString('N')
    $jb = Start-Job -ScriptBlock $job
    $script:AsyncStore[$id] = @{ Job = $jb; Done = $onDone }
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 300
    $timer.Tag = $id
    $timer.Add_Tick({
        $entry = $script:AsyncStore[$this.Tag]
        if (-not $entry) { return }
        if ($entry.Job.State -ne 'Running') {
            $this.Stop(); $this.Dispose()
            Receive-Job $entry.Job -ErrorAction SilentlyContinue | ForEach-Object { Add-Output $_ }
            Remove-Job $entry.Job -Force -ErrorAction SilentlyContinue
            $script:AsyncStore.Remove($this.Tag)
            if ($entry.Done) { & $entry.Done }
        }
    })
    $timer.Start()
}

# ---------------------------------------------------------------- actions
function Invoke-StartAll {
    Add-Output '--- Start All ---'
    Start-AsyncJob { & (Join-Path $using:Root 'scripts\start_all.cmd') 2>&1 } { Update-ServiceStatus; Refresh-ResourceMeters }
}
function Invoke-StopAll {
    Add-Output '--- Stop All ---'
    Start-AsyncJob {
        & (Join-Path $using:Root 'scripts\stop_apache.cmd') 2>&1
        & (Join-Path $using:Root 'scripts\stop_mariadb.cmd') 2>&1
    } { Update-ServiceStatus; Refresh-ResourceMeters }
}
function Invoke-RestartAll {
    Add-Output '--- Restart All ---'
    Start-AsyncJob {
        & (Join-Path $using:Root 'scripts\restart_apache.cmd') 2>&1
        & (Join-Path $using:Root 'scripts\restart_mariadb.cmd') 2>&1
    } { Update-ServiceStatus; Refresh-ResourceMeters }
}
function Invoke-Backup {
    Add-Output '--- Backup ---'
    Start-AsyncJob { & (Join-Path $using:Root 'scripts\backup.cmd') 2>&1 } { Refresh-LogList }
}
function Invoke-Health {
    Add-Output '--- Health Check ---'
    Start-AsyncJob { & (Join-Path $using:Root 'scripts\health_check.cmd') 2>&1 } { }
}
function Invoke-OpenPma { Start-Process "http://localhost:$($script:ApachePort)/phpmyadmin/"; Write-GuiLog 'opened phpMyAdmin' }
function Invoke-ViewLog {
    if ($script:LogList.SelectedItem) {
        $name = $script:LogList.SelectedItem.ToString()
        Add-Output ("--- {0} (last 80 lines) ---" -f $name)
        Get-Content -LiteralPath (Join-Path $script:LogDir $name) -Tail 80 | ForEach-Object { Add-Output $_ }
    }
}
function Invoke-ToggleStartup {
    if ($script:InitTaskToggle) { return }
    $want = $script:ChkStartup.Checked
    $t = Get-ScheduledTask -TaskName 'OZI-RIS Startup Safety Net' -ErrorAction SilentlyContinue
    if (-not $t) { Add-Output 'Task "OZI-RIS Startup Safety Net" not found.'; return }
    if (Get-IsAdmin) {
        if ($want) { Enable-ScheduledTask -TaskName 'OZI-RIS Startup Safety Net' | Out-Null }
        else       { Disable-ScheduledTask -TaskName 'OZI-RIS Startup Safety Net' | Out-Null }
        Add-Output ("Startup safety net " + $(if ($want) { 'ENABLED' } else { 'DISABLED' }))
        Write-GuiLog ("startup task -> " + $(if ($want) { 'enabled' } else { 'disabled' }))
    } else {
        Add-Output 'Toggle requires elevation - run panel as Administrator.'
        Refresh-TaskToggle
    }
}

# ---------------------------------------------------------------- UI build
$form = New-Object System.Windows.Forms.Form
$form.Text = 'OZI-RIS Server Manager'
$form.Size = New-Object System.Drawing.Size(760, 620)
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = New-Object System.Drawing.Size(720, 560)
$form.BackColor = [System.Drawing.Color]::White

$layout = New-Object System.Windows.Forms.TableLayoutPanel
$layout.Dock = 'Fill'
$layout.ColumnCount = 1
$layout.RowCount = 6
$layout.Padding = New-Object System.Windows.Forms.Padding(10)
$form.Controls.Add($layout)

# row 0: title
$title = New-Object System.Windows.Forms.Label
$title.Text = 'OZI-RIS Server Manager'
$title.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$layout.Controls.Add($title, 0, 0)

# row 1: service status + controls
$svcPanel = New-Object System.Windows.Forms.TableLayoutPanel
$svcPanel.ColumnCount = 6
$svcPanel.RowCount = 1
$svcPanel.AutoSize = $true
$svcPanel.Padding = New-Object System.Windows.Forms.Padding(0, 6, 0, 6)

$script:LblApache = New-Object System.Windows.Forms.Label
$script:LblApache.Text = '...'
$script:LblApache.AutoSize = $true
$script:LblApache.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
$script:LblMaria = New-Object System.Windows.Forms.Label
$script:LblMaria.Text = '...'
$script:LblMaria.AutoSize = $true
$script:LblMaria.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)

$btnStart = New-Object System.Windows.Forms.Button; $btnStart.Text = 'Start';     $btnStart.AutoSize = $true
$btnStop  = New-Object System.Windows.Forms.Button; $btnStop.Text = 'Stop';      $btnStop.AutoSize = $true
$btnRest  = New-Object System.Windows.Forms.Button; $btnRest.Text = 'Restart';   $btnRest.AutoSize = $true
$btnStatus = New-Object System.Windows.Forms.Button; $btnStatus.Text = 'Refresh'; $btnStatus.AutoSize = $true

$svcPanel.Controls.Add((New-Object System.Windows.Forms.Label -Property @{Text='Apache24:'; AutoSize=$true}), 0, 0)
$svcPanel.Controls.Add($script:LblApache, 1, 0)
$svcPanel.Controls.Add((New-Object System.Windows.Forms.Label -Property @{Text='   MariaDB:'; AutoSize=$true}), 2, 0)
$svcPanel.Controls.Add($script:LblMaria, 3, 0)
$svcPanel.Controls.Add((New-Object System.Windows.Forms.Label -Property @{Text='   '; AutoSize=$true}), 4, 0)
$svcPanel.Controls.Add($btnStatus, 5, 0)
$layout.Controls.Add($svcPanel, 0, 1)

# row 2: resource meters
$resPanel = New-Object System.Windows.Forms.TableLayoutPanel
$resPanel.ColumnCount = 4
$resPanel.RowCount = 1
$resPanel.AutoSize = $true
$script:BarCpu = New-Object System.Windows.Forms.ProgressBar
$script:BarCpu.Maximum = 100; $script:BarCpu.Width = 200
$script:BarRam = New-Object System.Windows.Forms.ProgressBar
$script:BarRam.Maximum = 100; $script:BarRam.Width = 200
$script:LblCpu = New-Object System.Windows.Forms.Label
$script:LblCpu.Text = 'CPU'
$script:LblCpu.AutoSize = $true
$script:LblRam = New-Object System.Windows.Forms.Label
$script:LblRam.Text = 'RAM'
$script:LblRam.AutoSize = $true
$resPanel.Controls.Add($script:LblCpu, 0, 0)
$resPanel.Controls.Add($script:BarCpu, 1, 0)
$resPanel.Controls.Add((New-Object System.Windows.Forms.Label -Property @{Text='   '; AutoSize=$true}), 2, 0)
$resPanel.Controls.Add($script:LblRam, 3, 0)
$resPanel.Controls.Add($script:BarRam, 4, 0)
$layout.Controls.Add($resPanel, 0, 2)

# row 3: action buttons
$actPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$actPanel.AutoSize = $true
$actPanel.FlowDirection = 'LeftToRight'
$bStart  = New-Object System.Windows.Forms.Button; $bStart.Text = 'Start All'
$bStop   = New-Object System.Windows.Forms.Button; $bStop.Text = 'Stop All'
$bRestart= New-Object System.Windows.Forms.Button; $bRestart.Text = 'Restart All'
$bBackup = New-Object System.Windows.Forms.Button; $bBackup.Text = 'Backup Now'
$bHealth = New-Object System.Windows.Forms.Button; $bHealth.Text = 'Health Check'
$bPma    = New-Object System.Windows.Forms.Button; $bPma.Text = 'phpMyAdmin'
$bRefreshLogs = New-Object System.Windows.Forms.Button; $bRefreshLogs.Text = 'Refresh Logs'
foreach ($b in @($bStart,$bStop,$bRestart,$bBackup,$bHealth,$bPma,$bRefreshLogs)) {
    $b.AutoSize = $true; $actPanel.Controls.Add($b)
}
$script:ChkStartup = New-Object System.Windows.Forms.CheckBox
$script:ChkStartup.Text = 'Startup safety net (run at boot)'
$script:ChkStartup.AutoSize = $true
$actPanel.Controls.Add($script:ChkStartup)
$layout.Controls.Add($actPanel, 0, 3)

# row 4: log picker + output
$logRow = New-Object System.Windows.Forms.TableLayoutPanel
$logRow.ColumnCount = 2
$logRow.RowCount = 1
$logRow.Dock = 'Fill'
$script:LogList = New-Object System.Windows.Forms.ListBox
$script:LogList.Dock = 'Fill'
$script:LogList.Width = 200
$script:OutputBox = New-Object System.Windows.Forms.TextBox
$script:OutputBox.Multiline = $true
$script:OutputBox.Dock = 'Fill'
$script:OutputBox.ScrollBars = 'Vertical'
$script:OutputBox.ReadOnly = $true
$script:OutputBox.Font = New-Object System.Drawing.Font('Consolas', 9)
[void]$logRow.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Absolute', 210)))
[void]$logRow.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Percent', 100)))
$logRow.Controls.Add($script:LogList, 0, 0)
$logRow.Controls.Add($script:OutputBox, 1, 0)
$layout.Controls.Add($logRow, 0, 4)

# row 5: footer
$footer = New-Object System.Windows.Forms.Label
$footer.Text = ("Install: {0}   HTTP: {1}   MySQL: {2}   DB: {3}" -f $script:Install, $script:ApachePort, $script:MysqlPort, $script:Cfg['db_name'])
$footer.AutoSize = $true
$footer.ForeColor = [System.Drawing.Color]::Gray
$layout.Controls.Add($footer, 0, 5)

# ---------------------------------------------------------------- events
$btnStart.Add_Click({ Invoke-StartAll })
$btnStop.Add_Click({ Invoke-StopAll })
$btnRest.Add_Click({ Invoke-RestartAll })
$btnStatus.Add_Click({ Update-ServiceStatus; Refresh-ResourceMeters })
$bStart.Add_Click({ Invoke-StartAll })
$bStop.Add_Click({ Invoke-StopAll })
$bRestart.Add_Click({ Invoke-RestartAll })
$bBackup.Add_Click({ Add-Output '--- Backup ---'; Invoke-Backup })
$bHealth.Add_Click({ Add-Output '--- Health Check ---'; Invoke-Health })
$bPma.Add_Click({ Invoke-OpenPma })
$bRefreshLogs.Add_Click({ Refresh-LogList; Invoke-ViewLog })
$script:LogList.Add_DoubleClick({ Invoke-ViewLog })
$script:ChkStartup.Add_CheckedChanged({ Invoke-ToggleStartup })
$form.Add_Shown({
    Update-ServiceStatus
    Refresh-ResourceMeters
    Refresh-LogList
    Refresh-TaskToggle
    Write-GuiLog 'GUI panel started'
    Add-Output ('OZI-RIS Server Manager ready.  (HTTP ' + $script:ApachePort + ' / MySQL ' + $script:MysqlPort + ')')
})

$timer2 = New-Object System.Windows.Forms.Timer
$timer2.Interval = 2000
$timer2.Add_Tick({ Update-ServiceStatus; Refresh-ResourceMeters })
$timer2.Start()

# ---------------------------------------------------------------- elevate if needed
if (-not $script:Cfg['skip_elevate']) {
    $needAdmin = ($args -notcontains '-RunElevated')
    if ($needAdmin -and -not (Get-IsAdmin) -and -not $SmokeTest) {
        $ps1 = $MyInvocation.MyCommand.Path
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = 'powershell.exe'
        $psi.Arguments = '-NoProfile -ExecutionPolicy Bypass -File "' + $ps1 + '" -RunElevated'
        $psi.Verb = 'runas'
        $psi.UseShellExecute = $true
        try {
            [System.Diagnostics.Process]::Start($psi) | Out-Null
        } catch {
            [System.Windows.Forms.MessageBox]::Show('This panel requires Administrator privileges.', 'OZI-RIS', 'OK', 'Exclamation')
        }
        exit 0
    }
}

$form.Add_FormClosed({ Write-GuiLog 'GUI panel closed' })

if ($SmokeTest) {
    $t = New-Object System.Windows.Forms.Timer
    $t.Interval = 1500
    $t.Add_Tick({ $form.Close() })
    $t.Start()
}

[void]$form.ShowDialog()
