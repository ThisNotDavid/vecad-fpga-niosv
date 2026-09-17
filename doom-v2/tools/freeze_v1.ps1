$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$releaseRoot = Join-Path $projectRoot 'releases\v1.0.0'
if (Test-Path -LiteralPath $releaseRoot) { throw 'Release already exists; refusing to overwrite' }
New-Item -ItemType Directory -Path $releaseRoot | Out-Null
$entries = @()
$files = @(Get-ChildItem -LiteralPath (Join-Path $projectRoot 'hardware\output_files') -File)
$files += @(Get-ChildItem -LiteralPath (Join-Path $projectRoot 'build') -File)
foreach ($sub in @('niosv','diagnostic','desktop','tests')) {
    $files += @(Get-ChildItem -LiteralPath (Join-Path $projectRoot "build\$sub") -File | Where-Object { $_.Extension -in @('.elf','.exe','.json','.log','.png','.ppm','.map') })
}
foreach ($file in $files) {
    $relative = [IO.Path]::GetRelativePath($projectRoot, $file.FullName)
    $destination = Join-Path $releaseRoot $relative
    New-Item -ItemType Directory -Force -Path (Split-Path $destination) | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $destination
    $originalHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLower()
    if ((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLower() -ne $originalHash) { throw "Copy verification failed: $relative" }
    $entries += [ordered]@{ path=$relative.Replace('\','/'); bytes=$file.Length; sha256=$originalHash }
}
$sourcePaths = @('hardware','rtl','software','tests','tools','docs','README.md','THIRD_PARTY.md','.gitignore','NEXT_SESSION.md')
$snapshot = Join-Path $releaseRoot 'source-original'
New-Item -ItemType Directory -Path $snapshot | Out-Null
foreach ($name in $sourcePaths) {
    if ($name -eq 'hardware') {
        New-Item -ItemType Directory -Path (Join-Path $snapshot $name) | Out-Null
        Get-ChildItem -LiteralPath (Join-Path $projectRoot $name) -File | Copy-Item -Destination (Join-Path $snapshot $name)
    } else { Copy-Item -LiteralPath (Join-Path $projectRoot $name) -Destination $snapshot -Recurse }
}
$assetRoot = Join-Path $releaseRoot 'assets'
New-Item -ItemType Directory -Path $assetRoot | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets\freedoom-0.13.0.zip') -Destination $assetRoot
foreach ($file in @(Get-ChildItem -LiteralPath $snapshot -Recurse -File) + @(Get-ChildItem -LiteralPath $assetRoot -File)) {
    $entries += [ordered]@{ path=[IO.Path]::GetRelativePath($releaseRoot,$file.FullName).Replace('\','/'); bytes=$file.Length; sha256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLower() }
}
$vendorRoot = Join-Path $projectRoot 'vendor\doomgeneric'
& git -C $vendorRoot bundle create (Join-Path $releaseRoot 'doomgeneric.bundle') HEAD
if ($LASTEXITCODE) { throw 'Vendor source archive failed' }
$vendorBundle = Get-Item -LiteralPath (Join-Path $releaseRoot 'doomgeneric.bundle')
$entries += [ordered]@{path='doomgeneric.bundle';bytes=$vendorBundle.Length;sha256=(Get-FileHash $vendorBundle.FullName -Algorithm SHA256).Hash.ToLower()}
[ordered]@{version='1.0.0'; captured_utc=[DateTime]::UtcNow.ToString('o'); note='Historical artifacts copied without rebuilding. Board benchmark is uncontrolled, not a repeatable performance baseline.';files=$entries} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $releaseRoot 'manifest.json')
Write-Output "Preserved and verified $($entries.Count) files in $releaseRoot"
