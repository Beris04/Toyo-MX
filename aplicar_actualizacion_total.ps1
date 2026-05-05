$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$version = "2026-05-05-v5"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TOYO MX - ACTUALIZACION TOTAL V5" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1) Actualizar referencias en TODOS los HTML
$updated = 0
$scanned = 0
$changedFiles = @()

Get-ChildItem -Path $root -Recurse -File -Filter *.html | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content -LiteralPath $file -Raw -Encoding UTF8
    $original = $content

    $content = [regex]::Replace($content,'(href=["''][^"'']*pedido_assets/)pedido_app(?:_v\d+)?\.css(?:\?v=[^"'']*)?(["''])',"`$1pedido_app_v5.css?v=$version`$2",'IgnoreCase')
    $content = [regex]::Replace($content,'(src=["''][^"'']*pedido_assets/)pedido_app(?:_v\d+)?\.js(?:\?v=[^"'']*)?(["''])',"`$1pedido_app_v5.js?v=$version`$2",'IgnoreCase')

    if ($content -ne $original) {
        Set-Content -LiteralPath $file -Value $content -Encoding UTF8
        $updated++
        $changedFiles += (Resolve-Path -Relative -LiteralPath $file)
    }
    $scanned++
}

# 2) Reconstruir clients.json con RUTA EXACTA
$rows = New-Object System.Collections.Generic.List[Object]

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

# CSV de validación
$csvPath = Join-Path $root "validacion_rutas_case.csv"
$rows | Export-Csv -LiteralPath $csvPath -Encoding UTF8 -NoTypeInformation

# Log
$logPath = Join-Path $root "patch_actualizacion_log.txt"
@(
"VERSION=$version"
"HTML_ESCANEADOS=$scanned"
"HTML_ACTUALIZADOS=$updated"
"CLIENTES_EN_CLIENTS_JSON=$($rows.Count)"
""
"ARCHIVOS_HTML_ACTUALIZADOS:"
$changedFiles
) | Set-Content -LiteralPath $logPath -Encoding UTF8

Write-Host ""
Write-Host "OK - HTML escaneados: $scanned" -ForegroundColor Green
Write-Host "OK - HTML actualizados: $updated" -ForegroundColor Green
Write-Host "OK - Clientes en clients.json: $($rows.Count)" -ForegroundColor Green
Write-Host "Generados: clients.json, validacion_rutas_case.csv, patch_actualizacion_log.txt" -ForegroundColor Green
Write-Host ""
Pause
