param(
    [Parameter(Mandatory = $true)][string]$PackRoot,
    [Parameter(Mandatory = $true)][string]$Port,
    [switch]$Remove
)

# OZI-RIS Server Pack - create or remove Start Menu / Desktop shortcuts.

$ws = New-Object -ComObject WScript.Shell
$sm = Join-Path $PackRoot 'scripts\server_manager.cmd'
$hc = Join-Path $PackRoot 'scripts\health_check.cmd'
$un = Join-Path $PackRoot 'installer\uninstall.cmd'
$pmaUrl = "http://localhost:$Port/phpmyadmin/"

$desktop = [Environment]::GetFolderPath('Desktop')
$startMenu = Join-Path ([Environment]::GetFolderPath('Programs')) 'OZI-RIS Server Pack'
$desktopLink = Join-Path $desktop 'OZI-RIS Server Manager.lnk'

if ($Remove) {
    if (Test-Path -LiteralPath $desktopLink) { Remove-Item -LiteralPath $desktopLink -Force }
    if (Test-Path -LiteralPath $startMenu) { Remove-Item -LiteralPath $startMenu -Recurse -Force }
    Write-Host '[OK] Shortcuts removed'
    exit 0
}

if (-not (Test-Path -LiteralPath $sm)) { Write-Error "server_manager.cmd not found at $sm"; exit 1 }
if (-not (Test-Path -LiteralPath $hc)) { Write-Error "health_check.cmd not found at $hc"; exit 1 }
if (-not (Test-Path -LiteralPath $un)) { Write-Error "uninstall.cmd not found at $un"; exit 1 }

$s = $ws.CreateShortcut($desktopLink)
$s.TargetPath = $sm
$s.WorkingDirectory = (Split-Path $sm)
$s.Description = 'OZI-RIS Server Manager'
$s.Save()

New-Item -ItemType Directory -Path $startMenu -Force | Out-Null

$pairs = @{
    'OZI-RIS Server Manager.lnk' = $sm
    'Health Check.lnk'           = $hc
    'Uninstall.lnk'              = $un
}
foreach ($k in $pairs.Keys) {
    $s = $ws.CreateShortcut((Join-Path $startMenu $k))
    $s.TargetPath = $pairs[$k]
    $s.WorkingDirectory = (Split-Path $pairs[$k])
    $s.Description = 'OZI-RIS Server Pack'
    $s.Save()
}

$urlFile = Join-Path $startMenu 'phpMyAdmin.url'
Set-Content -LiteralPath $urlFile -Value "[InternetShortcut]`r`nURL=$pmaUrl`r`n" -Encoding Default

Write-Host '[OK] Shortcuts created'
exit 0
