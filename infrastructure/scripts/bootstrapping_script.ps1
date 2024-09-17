param (
    [string]$storageAccountName,
    [string]$storageAccountKey,
    [string]$fileshareName,
    [string]$mountPath
)

# Create the fileshare mount
./mount_fileshare.ps1 -storageAccountName $storageAccountName -storageAccountKey $storageAccountKey -fileshareName $fileshareName -mountPath $mountPath