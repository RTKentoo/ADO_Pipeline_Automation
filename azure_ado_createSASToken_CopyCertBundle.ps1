#$ip = (Invoke-WebRequest -URI "http://ifconfig.me/ip").Content
$StartTime = Get-Date
$EndTime = $startTime.AddDays(1)
$certrenew_sas_token_uri = Get-AzStorageAccount -ResourceGroupName "resourceGroup" -Name "storageAccount" | Get-AzStorageContainer -Container certrenew | `
   New-AzStorageContainerSASToken `
     -Permission "racwdl" `
     -StartTime $StartTime `
     -ExpiryTime $EndTime `
     -FullURI

$pfxpush_sas_token_uri = Get-AzStorageAccount -ResourceGroupName "resourceGroup" -Name "storageAccount" | Get-AzStorageContainer -Container pfxpush | `
   New-AzStorageContainerSASToken `
     -Permission "racwdl" `
     -StartTime $StartTime `
     -ExpiryTime $EndTime `
     -FullURI

cd “C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy”
 .\AzCopy.exe /Source:$certrenew_sas_token_uri /Dest:"C:\Certs\CertRenew\"  /s /Y


cd "C:\Certs\certrenew\"
$old_pfx = (Get-ChildItem "C:\Certs\certrenew\" -File "*.pfx").Name
$secretName = (Get-ChildItem "C:\Certs\certrenew\" -File "*.pfx").BaseName
$certFriendlyName = ($secretName + "-" + (Get-Date -Format "MMddyyyy") + ".pfx")
$certName=(Get-ChildItem "C:\Certs\certrenew\" -File "*.crt" | Where-Object { !( $_.Name -eq "gd_bundle-g2-g1.crt")}).Name
$bundleName=(Get-ChildItem "C:\Certs\certrenew\" -File "gd_bundle-g2-g1.crt").Name
$certPass = Get-AzKeyVaultSecret -VaultName gfsi-w-certAutomation-kv -Name $secretName -AsPlainText

write-output "Running OpenSSL"
cd "C:\Program Files\OpenSSL-Win64\bin\"


.\openssl.exe pkcs12 -in "C:\Certs\certrenew\$old_pfx" -out "C:\Certs\certrenew\oldKey.pem" -passin pass:$certPass -passout pass:$certPass

.\openssl.exe rsa -in "C:\Certs\certrenew\oldKey.pem" -out "C:\Certs\certrenew\newKey.key" -passin pass:$certPass -passout pass:$certPass

.\openssl.exe pkcs12 -export -out "C:\Certs\pfxpush\$certFriendlyName" -inkey "C:\Certs\certrenew\newKey.key" -in "C:\Certs\certrenew\$certName" -certfile "C:\Certs\certrenew\$bundleName" -passout pass:$certPass

exit

cd “C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy”
.\AzCopy.exe /Source:"C:\Certs\pfxpush\" /Dest:$pfxpush_sas_token_uri /s /Y