# Script de création et signature du MSIX pour Caisse Dashboard

$certPassword = ConvertTo-SecureString -String "CaisseDashboard2024!" -Force -AsPlainText
$pfxPath = "$PSScriptRoot\caisse_dashboard_cert.pfx"
$msixPath = "$PSScriptRoot\build\windows\x64\runner\Release\caisse_dashboard.msix"

# Créer le certificat auto-signé
Write-Host "Création du certificat auto-signé..." -ForegroundColor Cyan
$cert = New-SelfSignedCertificate `
    -Type Custom `
    -Subject "CN=Caisse Dashboard" `
    -KeyUsage DigitalSignature `
    -FriendlyName "Caisse Dashboard" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")

Write-Host "Certificat créé. Thumbprint: $($cert.Thumbprint)" -ForegroundColor Green

# Exporter en PFX
Write-Host "Export du certificat en PFX..." -ForegroundColor Cyan
Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $certPassword | Out-Null
Write-Host "PFX exporté: $pfxPath" -ForegroundColor Green

# Signer le MSIX
Write-Host "Signature du MSIX..." -ForegroundColor Cyan
$signtool = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe"
if (-not (Test-Path $signtool)) {
    # Chercher signtool dans d'autres versions
    $signtool = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin" -Recurse -Filter "signtool.exe" |
        Where-Object { $_.FullName -match "x64" } |
        Select-Object -ExpandProperty FullName -First 1
}

if ($signtool) {
    & $signtool sign /fd sha256 /a /f $pfxPath /p "CaisseDashboard2024!" /tr http://timestamp.digicert.com /td sha256 $msixPath
    Write-Host "MSIX signé avec succès." -ForegroundColor Green
} else {
    Write-Host "signtool.exe introuvable. Installation du certificat uniquement." -ForegroundColor Yellow
}

# Installer le certificat dans Trusted Root (nécessite admin)
Write-Host "`nInstallation du certificat dans Trusted Root..." -ForegroundColor Cyan
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if ($isAdmin) {
    Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation "Cert:\LocalMachine\Root" -Password $certPassword | Out-Null
    Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation "Cert:\LocalMachine\TrustedPeople" -Password $certPassword | Out-Null
    Write-Host "Certificat installé dans Trusted Root et TrustedPeople." -ForegroundColor Green
} else {
    Write-Host "Non-admin: le certificat ne peut pas être installé dans Trusted Root automatiquement." -ForegroundColor Yellow
    Write-Host "Pour installer le MSIX, faites un clic droit sur le fichier .pfx > Installer > Machine locale > Trusted Root." -ForegroundColor Yellow
}

Write-Host "`n=== MSIX prêt ===" -ForegroundColor Green
Write-Host "Fichier: $msixPath" -ForegroundColor White
Write-Host "Certificat PFX: $pfxPath (mot de passe: CaisseDashboard2024!)" -ForegroundColor White
