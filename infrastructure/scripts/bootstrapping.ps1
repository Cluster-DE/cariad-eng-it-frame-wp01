param (
    [string]$storageAccountName = "",
    [string]$storageAccountKey = "",
    [string]$fileShareName = "",
    [string]$storageAccountConnectionString = "",
    [bool]$taskCreated = $false
)

$ErrorActionPreference = "Stop"

# Function to write log
function Write-Log {
    param (
        [string]$message,
        [string]$logLevel = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$logLevel] - $message"
    Add-Content -Path "C:\\CustomScriptExtensionLogs\\bootstrapping.log" -Value $logMessage
}

# Log file path
$mountDriveLetter = "Y"

if($taskCreated){
    # Wait for 5 minutes before starting the script
    Start-Sleep -Seconds 300
}

# Create log directory if it doesn't exist
if (-not (Test-Path -Path "C:\\CustomScriptExtensionLogs")) {
    New-Item -Path "C:\\CustomScriptExtensionLogs" -ItemType Directory
}

# Start logging
Write-Log "Script execution started." "INFO"

# Set environment variables
try{
    Write-Log "Setting environment variables for bootstrapping script." "INFO"
    setx STORAGE_ACCOUNT_CONNECTION_STRING $storageAccountConnectionString
}catch{
    Write-Log "Failed to set environment variable: $_" "ERROR"
    exit 1
}


# Check if the file share is already mounted
if (Test-Path -Path "$($mountDriveLetter):\") {
    Write-Log "File share already exists. Continuing with the script." "INFO"
} else {
    $user = "localhost\$storageAccountName"
    $shareEndpoint = "\\$storageAccountName.file.core.windows.net\$fileShareName"

    try{
        cmd.exe /C "cmdkey /add:`"$storageAccountName.file.core.windows.net`" /user:`"$user`" /pass:`"$storageAccountKey`""

        # Mount the drive
        New-PSDrive -Name $($mountDriveLetter) -PSProvider FileSystem -Root "$shareEndpoint" -Persist
    }catch{
        Write-Log "Failed to mount the file share: $_" "ERROR"
        exit 1
    }


    # Verify the mount
    if (Test-Path -Path "$($mountDriveLetter):\") {
        Write-Log "File share mounted successfully at $($mountDriveLetter):\" "INFO"
    } else {
        Write-Log "Failed to mount the file share." "ERROR"
        exit 1
    }
}

### Install dotnet

# Define the URL for the .NET 8 SDK installer
$dotnetInstallerUrl = "https://download.visualstudio.microsoft.com/download/pr/f5f1c28d-7bc9-431e-98da-3e2c1bbd1228/864e152e374b5c9ca6d58ee953c5a6ed/dotnet-sdk-8.0.401-win-x64.exe"

# Define the path to save the installer
$installerPath = "C:\Temp\dotnet-sdk-8.0.401-win-x64.exe"

# Create the Temp directory if it doesn't exist
if (-not (Test-Path -Path "C:\Temp")) {
    New-Item -Path "C:\Temp" -ItemType Directory
}

# Check if .NET 8 SDK is already installed
try {
    $dotnetVersion = & "C:\Program Files\dotnet\dotnet.exe" --list-sdks | Select-String "8.0.401"
    if ($dotnetVersion) {
        Write-Log ".NET 8 SDK is already installed: $dotnetVersion" 
        exit 0
    }
} catch {
    Write-Log ".NET 8 SDK missing. Installing now: $_" 
}

# Download the .NET 8 SDK installer
try {
    Invoke-WebRequest -Uri $dotnetInstallerUrl -OutFile $installerPath
    Write-Log "Downloaded .NET 8 SDK installer." 
} catch {
    Write-Log "Failed to download .NET 8 SDK installer: $_" 
    exit 1
}

# Install the .NET 8 SDK
try {
    Start-Process -FilePath $installerPath -ArgumentList "/quiet", "/norestart" -Wait
    Write-Log "Installed .NET 8 SDK." 
} catch {
    Write-Log "Failed to install .NET 8 SDK: $_" 
    exit 1
}


# Verify the installation
try {
    $dotnetVersion = & "C:\Program Files\dotnet\dotnet.exe" --list-sdks | Select-String "8.0.401"
    if ($dotnetVersion) {
        Write-Log "Verified .NET 8 SDK installation: $dotnetVersion" 
    } else {
        Write-Log "Failed to verify .NET 8 SDK installation." 
        exit 1
    }
} catch {
    Write-Log "Failed to verify .NET 8 SDK installation: $_" 
    exit 1
}

# End logging
Write-Log "Script execution completed." 