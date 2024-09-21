param (
    [string]$storageAccountName,
    [string]$storageAccountKey,
    [string]$storagePrivateDomain,
    [string]$fileshareName,
    [string]$storageAccountConnectionString
)

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

# Fetch values from environment variables if not provided as parameters
$storageAccountName = $storageAccountName -or (Get-Item -Path Env:STORAGE_ACCOUNT_NAME).Value
$storageAccountKey = $storageAccountKey -or (Get-Item -Path Env:STORAGE_ACCOUNT_KEY).Value
$storagePrivateDomain = $storagePrivateDomain -or (Get-Item -Path Env:STORAGE_PRIVATE_DOMAIN).Value
$fileshareName = $fileshareName -or (Get-Item -Path Env:FILESHARE_NAME).Value
$storageAccountConnectionString = $storageAccountConnectionString -or (Get-Item -Path Env:STORAGE_ACCOUNT_CONNECTION_STRING).Value


# Log file path
$logFilePathBootstrapping = "C:\\CustomScriptExtensionLogs\\bootstrapping.log"
$logFilePathFileshare = "C:\\CustomScriptExtensionLogs\\fileshare.log"
$mountDriveLetter = "Y"

# Create log directory if it doesn't exist
if (-not (Test-Path -Path "C:\\CustomScriptExtensionLogs")) {
    New-Item -Path "C:\\CustomScriptExtensionLogs" -ItemType Directory
}

# Start logging
Write-Log "Script execution started." $logFilePathBootstrapping


# Check if the file share is already mounted
if (Test-Path -Path "$($mountDriveLetter):\") {
    Write-Log "File share already exists. Continuing with the script." $logFilePathFileshare
} else {
    # Mount the file share
    try {

        # Convert the plain-text password into a SecureString
        $securePassword = ConvertTo-SecureString $storageAccountKey -AsPlainText -Force

        # Create PSCredential object
        $credential = New-Object System.Management.Automation.PSCredential ($storageAccountName, $securePassword)

        # Mount the Azure File Share using New-PSDrive
        $output = New-PSDrive -Name $mountDriveLetter -PSProvider FileSystem -Root "\\$storageAccountName.file.core.windows.net\$fileShareName" -Credential $credential -Persist 2>&1 | Out-String
        Write-Log "Attempted to mount the file share. Message: $output" $logFilePathFileshare
    } catch {
        Write-Log "Failed to mount the file share: $_" $logFilePathFileshare
        exit 1
    }

    # Verify the mount
    if (Test-Path -Path "$($mountDriveLetter):\") {
        Write-Log "File share mounted successfully at $($mountDriveLetter):\" $logFilePathFileshare
    } else {
        Write-Log "Failed to mount the file share." $logFilePathFileshare
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