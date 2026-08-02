param(
    [Parameter(Mandatory = $true)][string]$XamppPath,
    [Parameter(Mandatory = $true)][string]$InstallPath,
    [ValidateSet('PhpIni', 'Vhost', 'Both')][string]$Mode = 'Both'
)

# OZI-RIS Server Pack - XAMPP migration helper.
# Fixes the imported php.ini paths and imports VirtualHost blocks,
# rewriting XAMPP paths to the new install location.

$ErrorActionPreference = 'Stop'

function Fix-PhpIni {
    $src = Join-Path $XamppPath 'php\php.ini'
    $dstDir = Join-Path $InstallPath 'php54'
    $dst = Join-Path $dstDir 'php.ini'
    $extDir = Join-Path $dstDir 'ext'
    $tmpDir = Join-Path $dstDir 'tmp'
    $logDir = Join-Path $dstDir 'logs'

    if (-not (Test-Path -LiteralPath $src)) {
        Write-Host "[WARN] XAMPP php.ini not found at $src - skipping"
        return
    }
    if (-not (Test-Path -LiteralPath $tmpDir)) { New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null }
    if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

    $lines = Get-Content -LiteralPath $src
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($line in $lines) {
        $trimmed = $line.TrimStart()
        if ($trimmed -match '^extension_dir\s*=') {
            $out.Add("extension_dir = `"$extDir`"")
        }
        elseif ($trimmed -match '^error_log\s*=') {
            $out.Add("error_log = `"$logDir\php-error.log`"")
        }
        elseif ($trimmed -match '^(upload_tmp_dir|session\.save_path)\s*=') {
            $out.Add(($trimmed -split '=')[0].Trim() + " = `"$tmpDir`"")
        }
        elseif ($trimmed -match '^extension\s*=\s*([\w.]+\.dll)') {
            $dll = $matches[1]
            if (Test-Path (Join-Path $extDir $dll)) {
                $out.Add($line)
            } else {
                $out.Add('; ' + $line + ' ; missing in OZI-RIS php54 build')
            }
        }
        else {
            $out.Add($line)
        }
    }
    $out | Set-Content -LiteralPath $dst -Encoding Default -Force
    Write-Host "[OK] Imported and fixed php.ini -> $dst"
}

function Import-Vhost {
    $dst = Join-Path $InstallPath 'apache24\conf\vhost.conf'
    if (-not (Test-Path -LiteralPath $dst)) {
        Write-Host "[WARN] Target vhost.conf not found at $dst - Apache may not be installed yet"
        return
    }

    $candidates = @(
        (Join-Path $XamppPath 'apache\conf\httpd.conf'),
        (Join-Path $XamppPath 'apache\conf\extra\httpd-vhosts.conf'),
        (Join-Path $XamppPath 'apache\conf\httpd-vhosts.conf')
    )
    $all = ""
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) { $all += (Get-Content -LiteralPath $c -Raw) + "`n" }
    }
    if (-not $all) {
        Write-Host "[WARN] No XAMPP Apache configuration found - skipping VirtualHost import"
        return
    }

    $m = [regex]::Matches($all, '(?s)<VirtualHost\s[^>]*>.*?</VirtualHost>')
    if ($m.Count -eq 0) {
        Write-Host "[WARN] No VirtualHost blocks found in XAMPP configuration - skipping"
        return
    }

    $XamppPath = $XamppPath.TrimEnd('\', '/')
    $fw = $XamppPath.Replace('\', '/')
    $newBlock = "`r`n`r`n# --- Imported from XAMPP by migrate_xampp.cmd ---`r`n"
    foreach ($block in $m) {
        $b = $block.Value
        $b = $b.Replace($XamppPath + '\htdocs', $InstallPath + '\www')
        $b = $b.Replace($fw + '/htdocs', $InstallPath + '\www')
        $b = $b.Replace($XamppPath, $InstallPath)
        $b = $b.Replace($fw, $InstallPath)
        $newBlock += $b + "`r`n"
    }
    Add-Content -LiteralPath $dst -Value $newBlock -Encoding Default
    Write-Host "[OK] Imported $($m.Count) VirtualHost block(s) into $dst"
}

if ($Mode -in @('PhpIni', 'Both')) { Fix-PhpIni }
if ($Mode -in @('Vhost', 'Both')) { Import-Vhost }
exit 0
