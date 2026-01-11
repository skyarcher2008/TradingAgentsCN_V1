# One-time SSH key setup for NAS (Windows PowerShell)
# After this, deploy_to_nas.ps1 should not prompt for password.

$NAS_USER = "skyarcher"
$NAS_IP = "192.168.68.100"
$NAS_PORT = "10000"

$sshDir = Join-Path $env:USERPROFILE ".ssh"
$keyPath = Join-Path $sshDir "id_ed25519"
$pubPath = "$keyPath.pub"

if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir | Out-Null
}

if (-not (Test-Path $keyPath)) {
    Write-Host "Generating SSH key..." -ForegroundColor Green
    ssh-keygen -t ed25519 -f $keyPath -N "" | Out-Null
}

if (-not (Test-Path $pubPath)) {
    Write-Error "Public key not found: $pubPath"
    exit 1
}

$pubKey = (Get-Content -Path $pubPath -Raw -Encoding UTF8).Trim()

Write-Host "Copying SSH public key to NAS..." -ForegroundColor Green
Write-Host "NOTE: You will be prompted for NAS password ONE TIME." -ForegroundColor Yellow

ssh -p $NAS_PORT $NAS_USER@$NAS_IP "mkdir -p ~/.ssh; chmod 700 ~/.ssh; echo '$pubKey' >> ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys"

Write-Host "Done. Test passwordless login:" -ForegroundColor Green
Write-Host "  ssh -p $NAS_PORT $NAS_USER@$NAS_IP \"echo ok\"" -ForegroundColor Gray
