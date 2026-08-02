param(
    [switch]$Json
)

# OZI-RIS Server Pack - Health Check core.
# Verifies Apache, PHP, MariaDB, ports, disk, RAM, CPU and services.
# Exit code: 0 = HEALTHY, 1 = WARNING, 2 = CRITICAL.

$ErrorActionPreference = 'SilentlyContinue'

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ini = @{}
Get-Content -LiteralPath (Join-Path $root 'config\server.ini') | ForEach-Object {
    if ($_ -match '^\s*([^;#=\[]+)=(.*)$') {
        $ini[$matches[1].Trim()] = $matches[2].Trim()
    }
}
$apachePort = $ini['apache_port']
$mysqlPort  = $ini['mysql_port']
$install    = $ini['install_path']
$dbName     = $ini['db_name']
$dbUser     = $ini['db_user']
$dbPass     = $ini['db_pass']

$results = [System.Collections.Generic.List[object]]::new()
function Add-Result($name, $status, $detail) {
    $results.Add([pscustomobject]@{ Name = $name; Status = $status; Detail = $detail })
}

# ---- services ----
$svc = Get-Service -Name 'Apache24'
if (-not $svc) {
    Add-Result 'Apache service' 'CRIT' 'Apache24 not installed'
} elseif ($svc.Status -eq 'Running') {
    Add-Result 'Apache service' 'OK' 'running'
} else {
    Add-Result 'Apache service' 'CRIT' ("state: " + $svc.Status)
}

$svc = Get-Service -Name 'MariaDB'
if (-not $svc) {
    Add-Result 'MariaDB service' 'CRIT' 'MariaDB not installed'
} elseif ($svc.Status -eq 'Running') {
    Add-Result 'MariaDB service' 'OK' 'running'
} else {
    Add-Result 'MariaDB service' 'CRIT' ("state: " + $svc.Status)
}

# ---- ports ----
$conn = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue
if (($conn | Where-Object { $_.LocalPort -eq [int]$apachePort })) {
    Add-Result 'HTTP port' 'OK' ("TCP {0} listening" -f $apachePort)
} else {
    Add-Result 'HTTP port' 'CRIT' ("TCP {0} not listening" -f $apachePort)
}
if (($conn | Where-Object { $_.LocalPort -eq [int]$mysqlPort })) {
    Add-Result 'DB port' 'OK' ("TCP {0} listening" -f $mysqlPort)
} else {
    Add-Result 'DB port' 'CRIT' ("TCP {0} not listening" -f $mysqlPort)
}

# ---- PHP endpoint ----
$phpOk = $false
try {
    $resp = Invoke-WebRequest -Uri ("http://127.0.0.1:{0}/health.php" -f $apachePort) -UseBasicParsing -TimeoutSec 10
    if ($resp.StatusCode -eq 200) {
        $body = $resp.Content
        if ($body -match '"mysqli":\s*(true|false)') {
            if ($matches[1] -eq 'true') {
                $phpOk = $true
                Add-Result 'PHP stack' 'OK' ('php ' + ([regex]::Match($body, '"php":\s*"([^"]+)"').Groups[1].Value) + ', mysqli OK')
            } else {
                Add-Result 'PHP stack' 'CRIT' 'health.php reported mysqli missing'
            }
        } else {
            Add-Result 'PHP stack' 'CRIT' 'health.php did not return valid JSON'
        }
    } else {
        Add-Result 'PHP stack' 'CRIT' ("HTTP " + $resp.StatusCode)
    }
} catch {
    Add-Result 'PHP stack' 'CRIT' 'health.php unreachable'
}

# ---- PHP CLI binary ----
$phpExe = Join-Path $install 'php54\php.exe'
if (Test-Path $phpExe) {
    $ver = & $phpExe -v 2>&1 | Select-Object -First 1
    if ($LASTEXITCODE -eq 0 -and $ver) {
        Add-Result 'PHP CLI' 'OK' $ver
    } else {
        Add-Result 'PHP CLI' 'WARN' 'php.exe present but did not run (VC9 runtime?)'
    }
} else {
    Add-Result 'PHP CLI' 'WARN' 'php.exe not found'
}

# ---- database connectivity ----
$dbOk = $false
if ($phpOk) {
    $db = Join-Path $install 'mariadb\bin\mysql.exe'
    if (Test-Path $db) {
        $out = & $db -u $dbUser ("-p" + $dbPass) -h 127.0.0.1 -P $mysqlPort -e "SELECT 1;" 2>&1
        if ($LASTEXITCODE -eq 0) {
            $dbOk = $true
            Add-Result 'Database login' 'OK' ("user '{0}' can connect" -f $dbUser)
        } else {
            Add-Result 'Database login' 'CRIT' 'application user cannot log in'
        }
    } else {
        Add-Result 'Database login' 'CRIT' 'mysql.exe not found'
    }
} else {
    Add-Result 'Database login' 'SKIP' 'skipped (PHP stack not healthy)'
}

# ---- disk ----
$drive = ($install -split ':')[0]
$ps = Get-PSDrive -Name $drive -ErrorAction SilentlyContinue
if ($ps) {
    $total = $ps.Used + $ps.Free
    $freePct = [math]::Round($ps.Free / $total * 100)
    if ($freePct -lt 10) { Add-Result 'Disk' 'CRIT' ("{0}: {1}% free" -f $drive, $freePct) }
    elseif ($freePct -lt 20) { Add-Result 'Disk' 'WARN' ("{0}: {1}% free" -f $drive, $freePct) }
    else { Add-Result 'Disk' 'OK' ("{0}: {1}% free" -f $drive, $freePct) }
} else {
    Add-Result 'Disk' 'WARN' 'cannot query drive'
}

# ---- memory ----
$os = Get-CimInstance Win32_OperatingSystem
if ($os) {
    $freeMb = [math]::Round($os.FreePhysicalMemory / 1024)
    $totalMb = [math]::Round($os.TotalVisibleMemorySize / 1024)
    $freePct = [math]::Round($os.FreePhysicalMemory / $os.TotalVisibleMemorySize * 100)
    if ($freePct -lt 5) { Add-Result 'Memory' 'CRIT' ("{0} MB free of {1} MB ({2}%)" -f $freeMb, $totalMb, $freePct) }
    elseif ($freePct -lt 10) { Add-Result 'Memory' 'WARN' ("{0} MB free of {1} MB ({2}%)" -f $freeMb, $totalMb, $freePct) }
    else { Add-Result 'Memory' 'OK' ("{0} MB free of {1} MB ({2}%)" -f $freeMb, $totalMb, $freePct) }
} else {
    Add-Result 'Memory' 'WARN' 'cannot query memory'
}

# ---- CPU ----
$cpu = $null
$cpu = Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor | Where-Object { $_.Name -eq '_Total' }
if ($cpu) {
    $load = [int]$cpu.PercentProcessorTime
    if ($load -ge 95) { Add-Result 'CPU' 'CRIT' ("{0}% load" -f $load) }
    elseif ($load -ge 80) { Add-Result 'CPU' 'WARN' ("{0}% load" -f $load) }
    else { Add-Result 'CPU' 'OK' ("{0}% load" -f $load) }
} else {
    Add-Result 'CPU' 'WARN' 'cannot query CPU'
}

# ---- summary ----
$worst = 'OK'
foreach ($r in $results) {
    if ($r.Status -eq 'CRIT') { $worst = 'CRIT'; break }
    if ($r.Status -eq 'WARN' -and $worst -ne 'CRIT') { $worst = 'WARN' }
}

if ($Json) {
    [pscustomobject]@{ status = $worst.ToLower(); checks = $results } | ConvertTo-Json -Depth 4
} else {
    foreach ($r in $results) {
        $icon = switch ($r.Status) { 'OK' { '[OK]  ' } 'WARN' { '[WARN]' } 'CRIT' { '[CRIT]' } 'SKIP' { '[SKIP]' } }
        "{0} {1,-18} {2}" -f $icon, $r.Name, $r.Detail
    }
    ""
    "Summary: " + $worst
}

switch ($worst) {
    'CRIT' { exit 2 }
    'WARN' { exit 1 }
    default { exit 0 }
}
