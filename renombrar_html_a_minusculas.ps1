# Renombrar archivos HTML a minusculas para GitHub Pages
# USO:
# 1) Abre GitHub Desktop > Repository > Open in Terminal
# 2) Ejecuta: powershell -ExecutionPolicy Bypass -File .\renombrar_html_a_minusculas.ps1
# 3) Revisa GitHub Desktop y haz Commit + Push

$ErrorActionPreference = "Stop"

function Get-RelativePathSafe($base, $path) {
    $baseUri = New-Object System.Uri(($base.TrimEnd('\') + '\'))
    $pathUri = New-Object System.Uri($path)
    return [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($pathUri).ToString()).Replace('/', '\')
}

$repo = (Get-Location).Path
if (-not (Test-Path (Join-Path $repo ".git"))) {
    Write-Host "ERROR: Este script debe ejecutarse dentro de la carpeta principal del repositorio GitHub." -ForegroundColor Red
    Write-Host "Tip: En GitHub Desktop usa Repository > Open in Terminal." -ForegroundColor Yellow
    exit 1
}

Write-Host "Repositorio detectado: $repo" -ForegroundColor Cyan
Write-Host "Buscando archivos .html con mayusculas..." -ForegroundColor Cyan

# Ayuda a Git a detectar cambios de mayusculas/minusculas.
git config core.ignorecase false | Out-Null

$files = Get-ChildItem -Path $repo -Recurse -File -Filter "*.html" |
    Where-Object { $_.FullName -notmatch "\\.git\\" } |
    Sort-Object FullName

$renamed = 0
$skipped = 0

foreach ($file in $files) {
    $oldName = $file.Name
    $newName = $oldName.ToLowerInvariant()

    if ($oldName -ceq $newName) { continue }

    $dir = $file.DirectoryName
    $oldPath = $file.FullName
    $finalPath = Join-Path $dir $newName

    # Renombre temporal para que Windows y Git detecten el cambio de mayusculas a minusculas.
    $tmpName = "__tmp_casefix_$([Guid]::NewGuid().ToString('N')).html"
    $tmpPath = Join-Path $dir $tmpName

    if ((Test-Path -LiteralPath $finalPath) -and ($oldPath -cne $finalPath)) {
        Write-Host "OMITIDO por posible duplicado: $oldPath -> $finalPath" -ForegroundColor Yellow
        $skipped++
        continue
    }

    Rename-Item -LiteralPath $oldPath -NewName $tmpName
    Rename-Item -LiteralPath $tmpPath -NewName $newName

    $relOld = Get-RelativePathSafe $repo $oldPath
    $relNew = Get-RelativePathSafe $repo $finalPath
    Write-Host "Renombrado: $relOld -> $relNew" -ForegroundColor Green
    $renamed++
}

# Actualizar clients.json para asegurar que los paths apunten a minusculas.
$clientJsonFiles = Get-ChildItem -Path $repo -Recurse -File -Filter "clients.json" |
    Where-Object { $_.FullName -notmatch "\\.git\\" }

foreach ($jsonFile in $clientJsonFiles) {
    try {
        $raw = Get-Content -LiteralPath $jsonFile.FullName -Raw -Encoding UTF8
        $data = $raw | ConvertFrom-Json
        $changed = $false

        foreach ($item in $data) {
            if ($null -ne $item.path) {
                $lowerPath = ([string]$item.path).ToLowerInvariant()
                if ($item.path -cne $lowerPath) { $item.path = $lowerPath; $changed = $true }
            }
            if ($null -ne $item.vendor_folder) {
                $lowerVendor = ([string]$item.vendor_folder).ToLowerInvariant()
                if ($item.vendor_folder -cne $lowerVendor) { $item.vendor_folder = $lowerVendor; $changed = $true }
            }
        }

        if ($changed) {
            $data | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $jsonFile.FullName -Encoding UTF8
            Write-Host "Actualizado clients.json: $($jsonFile.FullName)" -ForegroundColor Green
        }
    } catch {
        Write-Host "No pude actualizar $($jsonFile.FullName): $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

git add -A

Write-Host "" 
Write-Host "Listo. Archivos HTML renombrados a minusculas: $renamed" -ForegroundColor Cyan
if ($skipped -gt 0) { Write-Host "Omitidos por posible duplicado: $skipped" -ForegroundColor Yellow }
Write-Host "Ahora revisa GitHub Desktop, haz Commit y despues Push." -ForegroundColor Cyan
