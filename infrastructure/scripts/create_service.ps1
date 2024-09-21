param (
    [string]$DownloadedFile,          # Path to the downloaded setup script (setup_script.ps1)
    [string]$DestinationFolder = "C:\scripts",  # Directory to copy the file to (default C:\scripts)
    [string]$Username,                # Username to run the service
    [string]$storageAccountName,
    [string]$storageAccountKey,
    [string]$storagePrivateDomain,
    [string]$fileshareName,
    [string]$storageAccountConnectionString
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param (
        [string]$message,
        [string]$logLevel = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$logLevel] - $message"
    Add-Content -Path "C:\\CustomScriptExtensionLogs\\create_service.log" -Value $logMessage
}

# Create log directory if it doesn't exist
if (-not (Test-Path -Path "C:\\CustomScriptExtensionLogs")) {
    New-Item -Path "C:\\CustomScriptExtensionLogs" -ItemType Directory
}

# Until private link doesnt work, set it to the default value
$storagePrivateDomain = "$storageAccountName.file.core.windows.net"

# Set environment variables
try {
    Write-Log "Setting environment variables for bootstrapping script." "INFO"

    # GET SID. SID is available, but the processes creating REGISTRY entries are not created until the user logs in.
    # Currently we have the requirement for the user to log in first, before this process works. 
    # Due to time constraints, we were not able to fix this, but this would be solvable.
    $sid = (Get-WmiObject win32_useraccount -Filter "Name='$Username'").SID



    # Use Registry to directly set the environment variable for future processes
    Set-ItemProperty -Path "Registry::HKEY_USERS\$sid\Environment" -Name 'STORAGE_ACCOUNT_CONNECTION_STRING' -Value $storageAccountConnectionString -Type String
    Set-ItemProperty -Path "Registry::HKEY_USERS\$sid\Environment" -Name 'STORAGE_ACCOUNT_NAME' -Value $storageAccountName -Type String
    Set-ItemProperty -Path "Registry::HKEY_USERS\$sid\Environment" -Name 'STORAGE_ACCOUNT_KEY' -Value $storageAccountKey -Type String
    Set-ItemProperty -Path "Registry::HKEY_USERS\$sid\Environment" -Name 'STORAGE_PRIVATE_DOMAIN' -Value $storagePrivateDomain -Type String
    Set-ItemProperty -Path "Registry::HKEY_USERS\$sid\Environment" -Name 'FILE_SHARE_NAME' -Value $fileshareName -Type String

    Write-Log "Environment variable set successfully." "INFO"

} catch {
    Write-Log "Failed to set environment variable: $_" "ERROR"
    exit 1
}

try{
    # Download from script extension download path. 
    # The download path contains another folder, which is a random integer. 
    # But there is always only one, so we just take the first one.
    $DownloadsBasePath = "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.18\Downloads"
    $DownloadFolder = Get-ChildItem -Path $DownloadsBasePath | Where-Object { $_.PSIsContainer } | Select-Object -First 1

    if (-not $DownloadFolder) {
        Write-Error "No folder found in the Downloads directory." "ERROR"
        exit 1
    }

    $DownloadedFilePath = Join-Path -Path $DownloadFolder.FullName -ChildPath $DownloadedFile

    Write-Log "Downloaded file $DownloadedFile path: $DownloadedFilePath\n" "INFO"

    if (-not (Test-Path -Path $DestinationFolder)) {
        New-Item -ItemType Directory -Path $DestinationFolder
    }

    # Copy to scripts folder
    $DestinationFile = Join-Path -Path $DestinationFolder -ChildPath (Split-Path -Leaf $DownloadedFile)

    Copy-Item -Path $DownloadedFilePath -Destination $DestinationFile -Force

    Write-Log "Copied $DownloadedFile to $DestinationFile" "INFO"

}catch{
    Write-Log "Failed to copy file: $_" "ERROR"
    exit 1
}

try{
    # Define the Startup folder path
    $startupFolder = "C:\users\$Username\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"

    # Remove existing shortcut, if there is one
    if(Test-Path "$startupFolder\$DownloadedFile.lnk"){
        Remove-Item "$startupFolder\$DownloadedFile.lnk"
    }

    # Create the shortcut
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$startupFolder\$DownloadedFile.lnk")
    $Shortcut.TargetPath = "Powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$DestinationFolder\$DownloadedFile`" -storageAccountName `"$storageAccountName`" -storageAccountKey `"$storageAccountKey`" -storagePrivateDomain `"$storagePrivateDomain`" -fileShareName `"$fileshareName`" -storageAccountConnectionString `"$storageAccountConnectionString`""
    $Shortcut.Save()
    
    Write-Log "Shortcut created in Startup folder." "INFO"
}catch{
    Write-Log "Failed to create shortcut: $_" "ERROR"
    exit 1
}

# This is a bit extreme, maybe could work on a better solution
Restart-Computer -Force    
