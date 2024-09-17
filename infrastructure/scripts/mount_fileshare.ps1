param (
    [string]$storageAccountName,
    [string]$storageAccountKey,
    [string]$fileshareName,
    [string]$mountPath
)

# Create the mount path if it doesn't exist
if (-not (Test-Path -Path $mountPath)) {
    New-Item -Path $mountPath -ItemType Directory
}

# Create the credential object
$secpasswd = ConvertTo-SecureString $storageAccountKey -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("Azure\$storageAccountName", $secpasswd)

# Mount the file share
New-PSDrive -Name "Z" -PSProvider FileSystem -Root "\\$storageAccountName.file.core.windows.net\$fileshareName" -Credential $credential -Persist

# Verify the mount
if (Test-Path -Path "Z:\") {
    Write-Output "File share mounted successfully at Z:\"
} else {
    Write-Output "Failed to mount the file share."
}

# Create a scheduled task to run this script on startup
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$PSScriptRoot\mount_fileshare.ps1`" -storageAccountName $storageAccountName -storageAccountKey $storageAccountKey -fileshareName $fileshareName -mountPath $mountPath"
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName "MountAzureFileShare" -Action $action -Trigger $trigger -Principal $principal -Settings $settings