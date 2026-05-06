$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TOYO MX - CORREGIR NaN Y RUTAS EXACTAS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$updatedHtml = 0
$nanFixCount = 0
$scanned = 0
$changedFiles = @()

function Get-ClientCode([string]$name) {
    $m = [regex]::Match($name,'((?:c|cpol|ctln|cgdl|czpn|ctjo|cslp|cags|cpn)[a-z0-9]+)','IgnoreCase')
    if ($m.Success) { return $m.Groups[1].Value.ToUpper() }
    return ""
}

function Get-ClientName([string]$name,[string]$code) {
    $base = [regex]::Replace($name,'\.html?$','',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($code) {
        $base = [regex]::Replace($base,[regex]::Escape($code),'',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    }
    $base = [regex]::Replace($base,'[_\-]+$','')
    $base = $base.Replace('_',' ').Replace('-',' ').Trim()
    $base = [regex]::Replace($base,'\s+',' ')
    return $base.ToUpper()
}

Get-ChildItem -Path $root -Recurse -File -Filter *.html | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content -LiteralPath $file -Raw -Encoding UTF8
    $original = $content

    $before = $content
    $content = [regex]::Replace($content, '"img"\s*:\s*NaN', '"img":""')
    $content = [regex]::Replace($content, ':\s*NaN([,\}])', ':null$1')
    $content = [regex]::Replace($content, ':\s*Infinity([,\}])', ':null$1')
    $content = [regex]::Replace($content, ':\s*-Infinity([,\}])', ':null$1')

    if ($content -ne $before) {
        $nanFixCount++
    }

    if ($content -ne $original) {
        Set-Content -LiteralPath $file -Value $content -Encoding UTF8
        $updatedHtml++
        $changedFiles += (Resolve-Path -Relative -LiteralPath $file)
    }
    $scanned++
}

$rows = New-Object System.Collections.Generic.List[Object]
Get-ChildItem -Path $root -Recurse -File -Filter *.html | ForEach-Object {
    if ($_.Name.ToLower() -eq "index.html") { return }
    $rel = $_.FullName.Substring($root.Length).TrimStart('\').Replace('\','/')
    $vendorFolder = ""
    if ($rel.Contains('/')) { $vendorFolder = $rel.Split('/')[0] }

    $rows.Add([PSCustomObject]@{
        vendor_folder = $vendorFolder
        vendor_label  = ($vendorFolder -replace '_',' ').ToUpper()
        client_name   = (Get-ClientName $_.Name (Get-ClientCode $_.Name))
        client_code   = (Get-ClientCode $_.Name)
        path          = $rel
    })
}
$rows = $rows | Sort-Object vendor_label, client_name, client_code, path

$clientsJsonPath = Join-Path $root "clients.json"
$rows | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $clientsJsonPath -Encoding UTF8

$csvPath = Join-Path $root "validacion_rutas_case.csv"
$rows | Export-Csv -LiteralPath $csvPath -Encoding UTF8 -NoTypeInformation

$logPath = Join-Path $root "fix_nan_log.txt"
@(
"HTML_ESCANEADOS=$scanned"
"HTML_CORREGIDOS=$updatedHtml"
"ARCHIVOS_CON_NAN_CORREGIDO=$nanFixCount"
"CLIENTES_EN_CLIENTS_JSON=$($rows.Count)"
""
"ARCHIVOS_HTML_CORREGIDOS:"
$changedFiles
) | Set-Content -LiteralPath $logPath -Encoding UTF8

Write-Host ""
Write-Host "OK - HTML escaneados: $scanned" -ForegroundColor Green
Write-Host "OK - HTML corregidos: $updatedHtml" -ForegroundColor Green
Write-Host "OK - Archivos con NaN corregido: $nanFixCount" -ForegroundColor Green
Write-Host "OK - Clients.json regenerado: $($rows.Count) clientes" -ForegroundColor Green
Write-Host ""
Pause
