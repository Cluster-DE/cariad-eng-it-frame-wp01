param (
    [string]$storageAccountName,
    [string]$storageAccountKey,
    [string]$storagePrivateDomain,
    [string]$fileshareName,
    [string]$storageAccountConnectionString
)

# Log file path
$logFilePathBootstrapping = "C:\CustomScriptExtensionLogs\bootstrapping.log"
$logFilePathFileshare = "C:\CustomScriptExtensionLogs\fileshare.log"

# Function to write log
function Write-Log {
    param (
        [string]$message,
        [string]$logFilePath
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
Write-Log "Script execution started." $logFilePathFileshare

# Set the storage account connection string as an environment variable
try {
    setx STORAGE_ACCOUNT_CONNECTION_STRING $storageAccountConnectionString
    Write-Log "Environment variable STORAGE_ACCOUNT_CONNECTION_STRING set successfully." $logFilePathFileshare
} catch {
    Write-Log "Failed to set environment variable: $_" $logFilePathFileshare
    exit 1
}

# Create the credential object
try {
    # Save the password so the drive will persist on reboot
    cmd.exe /C "cmdkey /add:`"$storagePrivateDomain`" /user:`"localhost\$storageAccountName`" /pass:`"$storageAccountKey`""
    Write-Log "Credentials added." $logFilePathFileshare
} catch {
    Write-Log "Failed to create credential object: $_" $logFilePathFileshare
    exit 1
}

# Check if the file share is already mounted
if (Test-Path -Path "Y:\") {
    Write-Log "File share already exists. Continuing with the script." $logFilePathFileshare
} else {
    # Mount the file share
    try {
        # Mount the drive using net use without specifying user and password
        cmd.exe /C "net use Y: \\$storagePrivateDomain\$fileshareName /persistent:yes"
        Write-Log "Attempted to mount the file share." $logFilePathFileshare
    } catch {
        Write-Log "Failed to mount the file share: $_" $logFilePathFileshare
        exit 1
    }

    # Verify the mount
    if (Test-Path -Path "Y:\") {
        Write-Log "File share mounted successfully at Y:\" $logFilePathFileshare
    } else {
        Write-Log "Failed to mount the file share." $logFilePathFileshare
        exit 1
    }
}

### Bootstrapping

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
        Write-Log ".NET 8 SDK is already installed: $dotnetVersion" $logFilePathBootstrapping
        exit 0
    }
} catch {
    Write-Log ".NET 8 SDK missing. Installing now: $_" $logFilePathBootstrapping
}

# Download the .NET 8 SDK installer
try {
    Invoke-WebRequest -Uri $dotnetInstallerUrl -OutFile $installerPath
    Write-Log "Downloaded .NET 8 SDK installer." $logFilePathBootstrapping
} catch {
    Write-Log "Failed to download .NET 8 SDK installer: $_" $logFilePathBootstrapping
    exit 1
}

# Install the .NET 8 SDK
try {
    Start-Process -FilePath $installerPath -ArgumentList "/quiet", "/norestart" -Wait
    Write-Log "Installed .NET 8 SDK." $logFilePathBootstrapping
} catch {
    Write-Log "Failed to install .NET 8 SDK: $_" $logFilePathBootstrapping
    exit 1
}

# Verify the installation
try {
    $dotnetVersion = & "C:\Program Files\dotnet\dotnet.exe" --list-sdks | Select-String "8.0.401"
    if ($dotnetVersion) {
        Write-Log "Verified .NET 8 SDK installation: $dotnetVersion" $logFilePathBootstrapping
    } else {
        Write-Log "Failed to verify .NET 8 SDK installation." $logFilePathBootstrapping
        exit 1
    }
} catch {
    Write-Log "Failed to verify .NET 8 SDK installation: $_" $logFilePathBootstrapping
    exit 1
}

# End logging
Write-Log "Script execution completed." $logFilePathBootstrapping