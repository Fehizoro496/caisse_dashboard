$msixPath = "D:\workspace\caisse_dashboard\build\windows\x64\runner\Release\caisse_dashboard.msix"
$sig = Get-AuthenticodeSignature $msixPath
Write-Host "Status: $($sig.Status)"
if ($sig.SignerCertificate) {
    Write-Host "Subject: $($sig.SignerCertificate.Subject)"
    Write-Host "Not After: $($sig.SignerCertificate.NotAfter)"
}
$sizeBytes = (Get-Item $msixPath).Length
$sizeMB = [math]::Round($sizeBytes / 1MB, 2)
Write-Host "Taille: $sizeMB MB"
