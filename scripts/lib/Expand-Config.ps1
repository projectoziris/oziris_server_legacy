param(
    [Parameter(Mandatory = $true)][string]$Template,
    [Parameter(Mandatory = $true)][string]$Output,
    [string]$MapFile = ""
)

# OZI-RIS Server Pack - template expansion helper.
# Placeholders such as @@NAME@@ inside the template are replaced with the
# values given in the map file (one "KEY=VALUE" per line, '#' = comment).

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Template)) {
    Write-Error "Template not found: $Template"
    exit 1
}

$content = Get-Content -LiteralPath $Template -Raw

if ($MapFile -and (Test-Path -LiteralPath $MapFile)) {
    foreach ($line in Get-Content -LiteralPath $MapFile) {
        if (-not $line) { continue }
        if ($line.Trim().StartsWith('#')) { continue }
        $i = $line.IndexOf('=')
        if ($i -gt 0) {
            $key = $line.Substring(0, $i).Trim()
            $val = $line.Substring($i + 1).Trim()
            if ($key) {
                $content = $content.Replace($key, $val)
            }
        }
    }
}

$outDir = Split-Path -Parent $Output
if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$content | Set-Content -LiteralPath $Output -Encoding Default -Force
exit 0
