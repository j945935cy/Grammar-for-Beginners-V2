param(
    [int]$Port = 8000,
    [switch]$Detached
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($Detached) {
    $command = "Set-Location -LiteralPath '$projectRoot'; Write-Host 'Starting local test server at http://localhost:$Port'; Write-Host 'Press Ctrl+C to stop.'; py -m http.server $Port"
    Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $command -WorkingDirectory $projectRoot
    Write-Host "Launched local test server in a new PowerShell window: http://localhost:$Port"
    exit 0
}

Write-Host "Starting local test server..."
Write-Host "Project root: $projectRoot"
Write-Host "URL: http://localhost:$Port"
Write-Host "Press Ctrl+C to stop."

Set-Location -LiteralPath $projectRoot
py -m http.server $Port
