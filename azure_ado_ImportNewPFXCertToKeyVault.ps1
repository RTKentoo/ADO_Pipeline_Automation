$secretName = (Get-ChildItem "C:\Certs\certrenew\" -File "*.pfx").BaseName

$Password = Get-AzKeyVaultSecret -VaultName 'keyvault' -Name $secretName -AsPlainText | ConvertTo-SecureString -AsPlainText -Force
$certFriendlyName = ($secretName + "-" + (Get-Date -Format "MMddyyyy"))

Import-AzKeyVaultCertificate `
    -VaultName "vault_name" `
    -Name $certFriendlyName `
    -FilePath ("C:/Certs/pfxpush/" + $certFriendlyName + ".pfx") `
    -Password $Password

Get-ChildItem "C:\Certs\Certrenew\*" -Recurse | Remove-Item
Get-ChildItem "C:\Certs\pfxPush\*" -Recurse | Remove-Item