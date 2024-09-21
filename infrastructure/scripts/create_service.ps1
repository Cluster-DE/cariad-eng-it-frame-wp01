param (
    [string]$DownloadedFile,          # Path to the downloaded setup script (setup_script.ps1)
    [string]$DestinationFolder = "C:\scripts",  # Directory to copy the file to (default C:\scripts)
    [string]$ServiceName = "RunSetupScriptService",  # Service name
    [string]$ServiceDescription = "Service to run setup_script.ps1 at startup",  # Description of the service
    [string]$Username,                # Username to run the service
    [string]$Password,                 # Password for the service account
    [string]$storageAccountName,
    [string]$storageAccountKey,
    [string]$storagePrivateDomain,
    [string]$fileshareName,
    [string]$storageAccountConnectionString
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
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

    Write-Log "Setting environment variables for bootstrapping script."

    # GET SID
    $sid = (Get-WmiObject win32_useraccount -Filter "Name='$Username'").SID

    # Use Registry to directly set the environment variable for future processes
    Set-ItemProperty -Path "Registry::HKEY_USERS\$sid\Environment" -Name 'STORAGE_ACCOUNT_CONNECTION_STRING' -Value $storageAccountConnectionString -Type String
    Set-ItemProperty -Path "Registry::HKEY_USERS\$sid\Environment" -Name 'STORAGE_ACCOUNT_NAME' -Value $storageAccountName -Type String
    Set-ItemProperty -Path "Registry::HKEY_USERS\$sid\Environment" -Name 'STORAGE_ACCOUNT_KEY' -Value $storageAccountKey -Type String
    Set-ItemProperty -Path "Registry::HKEY_USERS\$sid\Environment" -Name 'STORAGE_PRIVATE_DOMAIN' -Value $storagePrivateDomain -Type String
    Set-ItemProperty -Path "Registry::HKEY_USERS\$sid\Environment" -Name 'FILE_SHARE_NAME' -Value $fileshareName -Type String

    
    Write-Log "Environment variable set successfully."

} catch {
    Write-Log "Failed to set environment variable: $_"
    exit 1
}

# Step 1: Define the base path to the Downloads directory
$DownloadsBasePath = "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.18\Downloads"

# Step 2: Find the only folder in the Downloads directory
$DownloadFolder = Get-ChildItem -Path $DownloadsBasePath | Where-Object { $_.PSIsContainer } | Select-Object -First 1

if (-not $DownloadFolder) {
    Write-Error "No folder found in the Downloads directory."
    exit 1
}

# Step 3: Construct the full path to the downloaded file
$DownloadedFilePath = Join-Path -Path $DownloadFolder.FullName -ChildPath $DownloadedFile

# Step 4: Ensure the destination directory exists
if (-not (Test-Path -Path $DestinationFolder)) {
    New-Item -ItemType Directory -Path $DestinationFolder
}

# Step 5: Define the destination file path
$DestinationFile = Join-Path -Path $DestinationFolder -ChildPath (Split-Path -Leaf $DownloadedFile)

# Step 6: Copy the downloaded script to the destination folder
Copy-Item -Path $DownloadedFilePath -Destination $DestinationFile -Force
# Step 4: Remove the service if it already exists
if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
    Stop-Service -Name $ServiceName -Force
    
    sc.exe delete $ServiceName
    Start-Sleep -Seconds 5
}


Write-Log "Creating shortcut for script in Startup folder."

# Define the Startup folder path
$startupFolder = "C:\users\$Username\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"

# Create the shortcut
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$startupFolder\$DownloadedFile.lnk")
$Shortcut.TargetPath = "Powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$ScriptPath`""
$Shortcut.Save()

Write-Log "Shortcut created in Startup folder."