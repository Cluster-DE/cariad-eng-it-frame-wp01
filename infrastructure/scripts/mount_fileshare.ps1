param (
    [string]$storageAccountName,
    [string]$storageAccountKey,
    [string]$fileshareName,
    [string]$storageAccountConnectionString
)

# Log file path
$logFilePath = "C:\CustomScriptExtensionLogs\mount_fileshare.log"
$driveLetter = "F"
# Function to write log
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Add-Content -Path $logFilePath -Value $logMessage
}

# Create log directory if it doesn't exist
if (-not (Test-Path -Path "C:\CustomScriptExtensionLogs")) {
    New-Item -Path "C:\CustomScriptExtensionLogs" -ItemType Directory
}

# Start logging
Write-Log "Script execution started."


# Set the storage account connection string as an environment variable
try {
    setx STORAGE_ACCOUNT_CONNECTION_STRING $storageAccountConnectionString
    Write-Log "Environment variable STORAGE_ACCOUNT_CONNECTION_STRING set successfully."
} catch {
    Write-Log "Failed to set environment variable: $_"
    exit 1
}

# Create the credential object
try {
   # Save the password so the drive will persist on reboot
   cmd.exe /C "cmdkey /add:`"$storageAccountName.file.core.windows.net`" /user:`"localhost\$storageAccountName`" /pass:`"$storageAccountKey`""
   Write-Log "Credentials added."
} catch {
    Write-Log "Failed to create credential object: $_"
    exit 1
}

# Mount the file share
try {
   # Mount the drive
   # Mapping works, but it shows an error symbol on the folder icon. It doesnt seem to have any repurcussions, yet doesn't look good.
   New-PSDrive -Name $driveLetter -PSProvider FileSystem -Root "\\$storageAccountName.file.core.windows.net\$fileshareName" -Persist
   
   #cmd.exe /C "net use Z: \\$storageAccountName.file.core.windows.net\$fileshareName /user:localhost\$storageAccountName $storageAccountKey /persistent:yes"

   Write-Log "Attempted to mount the file share."
} catch {
    Write-Log "Failed to mount the file share: $_"
    exit 1
}

# Verify the mount
if (Test-Path -Path "Z:\") {
    Write-Log "File share mounted successfully at $driveLetter:\"
} else {
    Write-Log "Failed to mount the file share."
    exit 1
}

# End logging
Write-Log "Script execution completed."





