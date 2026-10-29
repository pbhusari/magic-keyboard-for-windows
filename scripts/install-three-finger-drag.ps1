# Installs ThreeFingerDragOnWindows 2.0.7 (https://github.com/ClementGre/ThreeFingerDragOnWindows, MIT)
# for macOS-style three-finger drag. No admin rights needed.
#
# Safety checks before installing:
#   - the download must match a known SHA-256
#   - the package must be signed by Microsoft's Store signing CA (the same build Microsoft certified)
# Requires the .NET 10 runtime; the script tells you if it's missing.
# Afterwards run set-touchpad-gestures.ps1 so Windows' own 3-finger swipes don't fight the drag.

$ErrorActionPreference = 'Stop'
$url = 'https://github.com/ClementGre/ThreeFingerDragOnWindows/releases/download/2.0.7/ThreeFingersDragOnWindows_2.0.7_x64.Msix'
$sha256 = '7CD82B22BA36BA5B6408F2A08F26613F3090C90721C878E298E581634135D999'

$runtimes = Join-Path $env:ProgramFiles 'dotnet\shared\Microsoft.NETCore.App'
if (-not (Get-ChildItem $runtimes -Directory -Filter '10.*' -ErrorAction SilentlyContinue)) {
    Write-Host '.NET 10 runtime not found. Install ".NET Desktop Runtime 10" (x64) from https://dotnet.microsoft.com/download/dotnet/10.0 first.'
    return
}

$work = Join-Path $env:TEMP ('three-finger-drag-' + [guid]::NewGuid())
New-Item -ItemType Directory $work | Out-Null
$msix = Join-Path $work 'ThreeFingersDragOnWindows.msix'
Invoke-WebRequest $url -OutFile $msix -UseBasicParsing

$actual = (Get-FileHash $msix -Algorithm SHA256).Hash
if ($actual -ne $sha256) { throw "Download hash mismatch ($actual). Not installing." }
$sig = Get-AuthenticodeSignature $msix
if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Issuer -notlike 'CN=Microsoft Marketplace CA*') {
    throw "Package isn't Store-signed (status $($sig.Status)). Not installing."
}

Add-AppxPackage -Path $msix
Remove-Item $work -Recurse -Force

$pkg = Get-AppxPackage *ThreeFingersDragOnWindows*
$appId = (Get-AppxPackageManifest $pkg).Package.Applications.Application.Id
Start-Process "shell:AppsFolder\$($pkg.PackageFamilyName)!$appId"
Write-Host "Installed $($pkg.Name) $($pkg.Version). Its settings are in the tray icon."
