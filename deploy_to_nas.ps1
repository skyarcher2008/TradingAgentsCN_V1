# TradingAgents NAS Deployment Script
# Connects to NAS, pulls code and restarts Docker

$NAS_USER = "skyarcher"
$NAS_IP = "192.168.68.100"
$NAS_PORT = "10000"

Write-Host "Connecting to NAS ($NAS_IP) to start deployment..." -ForegroundColor Green
Write-Host "NOTE: If prompted for password, type it and press Enter (no characters will be shown)." -ForegroundColor Yellow

# Read local bash script content
$ScriptPath = Join-Path $PSScriptRoot "deploy_to_nas_script.sh"
if (-not (Test-Path $ScriptPath)) {
    # Fallback for when running from a different context
    $ScriptPath = ".\deploy_to_nas_script.sh"
}

if (-not (Test-Path $ScriptPath)) {
    Write-Error "File not found: deploy_to_nas_script.sh"
    exit 1
}

# Read and convert to Unix line endings
$ScriptContent = Get-Content -Path $ScriptPath -Raw -Encoding UTF8
# Encode to Base64 to avoid shell escaping issues
$ScriptBytes = [System.Text.Encoding]::UTF8.GetBytes($ScriptContent)
$Base64Script = [Convert]::ToBase64String($ScriptBytes)

# Execute SSH command using Base64 decoding
# This prevents syntax errors caused by special characters like (...)
Write-Host "Sending script to NAS..." -ForegroundColor Gray
$SshArgs = @(
    "-p", $NAS_PORT,
    "-o", "ServerAliveInterval=30",
    "-o", "ServerAliveCountMax=3",
    "-t",
    "$NAS_USER@$NAS_IP",
    "echo $Base64Script | base64 -d | bash"
)
ssh @SshArgs
