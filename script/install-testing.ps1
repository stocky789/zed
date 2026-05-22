[CmdletBinding()]
param(
    [string]$Repo = $env:ZED_TESTING_REPO,
    [string]$Tag = $env:ZED_TESTING_TAG,
    [switch]$Silent
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if (-not $Repo) {
    $Repo = 'stocky789/zed'
}

if (-not $Tag) {
    $Tag = 'testing-latest'
}

$architecture = switch ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture) {
    'X64' { 'x86_64' }
    'Arm64' { 'aarch64' }
    default { throw "Unsupported architecture: $([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture)" }
}

$asset = "Zed-$architecture.exe"
$uri = "https://github.com/$Repo/releases/download/$Tag/$asset"
$temp = Join-Path ([System.IO.Path]::GetTempPath()) "zed-testing-$([System.Guid]::NewGuid())"
New-Item -ItemType Directory -Path $temp | Out-Null
$installer = Join-Path $temp $asset

try {
    Write-Host "Downloading $Repo $Tag $asset"
    Invoke-WebRequest -Uri $uri -OutFile $installer

    $arguments = @()
    if ($Silent) {
        $arguments += '/VERYSILENT'
        $arguments += '/SUPPRESSMSGBOXES'
        $arguments += '/NORESTART'
    }

    Write-Host "Starting installer"
    $process = Start-Process -FilePath $installer -ArgumentList $arguments -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        throw "Installer exited with code $($process.ExitCode)"
    }
} finally {
    Remove-Item -Path $temp -Recurse -Force -ErrorAction SilentlyContinue
}
