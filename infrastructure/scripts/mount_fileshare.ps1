param (
    [string]$storageAccountName,
    [string]$storageAccountKey,
    [string]$fileshareName
)

# Log file path
$logFilePath = "C:\CustomScriptExtensionLogs\mount_fileshare.log"

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

# Create the credential object
try {
    $secpasswd = ConvertTo-SecureString $storageAccountKey -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential ("Azure\$storageAccountName", $secpasswd)
    Write-Log "Credential object created successfully."
} catch {
    Write-Log "Failed to create credential object: $_"
    exit 1
}

# Mount the file share
try {
    New-PSDrive -Name "Z" -PSProvider FileSystem -Root "\\$storageAccountName.file.core.windows.net\$fileshareName" -Credential $credential -Persist
    Write-Log "Attempted to mount the file share."
} catch {
    Write-Log "Failed to mount the file share: $_"
    exit 1
}

# Verify the mount
if (Test-Path -Path "Z:\") {
    Write-Log "File share mounted successfully at Z:\"
} else {
    Write-Log "Failed to mount the file share."
    exit 1
}

# Create a scheduled task to run this script on startup
try {
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$PSScriptRoot\mount_fileshare.ps1`" -storageAccountName $storageAccountName -storageAccountKey $storageAccountKey -fileshareName $fileshareName"
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    Register-ScheduledTask -TaskName "MountAzureFileShare" -Action $action -Trigger $trigger -Principal $principal -Settings $settings
    Write-Log "Scheduled task created successfully."
} catch {
    Write-Log "Failed to create scheduled task: $_"
    exit 1
}

# End logging
Write-Log "Script execution completed."