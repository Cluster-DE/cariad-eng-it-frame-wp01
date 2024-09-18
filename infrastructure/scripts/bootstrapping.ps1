# Log file path
$logFilePath = "C:\CustomScriptExtensionLogs\bootstrapping.log"

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

# Define the URL for the .NET 8 runtime installer
$dotnetInstallerUrl = "https://download.visualstudio.microsoft.com/download/pr/12345678-1234-1234-1234-1234567890ab/dotnet-runtime-8.0.0-win-x64.exe"

# Define the path to save the installer
$installerPath = "C:\Temp\dotnet-runtime-8.0.0-win-x64.exe"

# Create the Temp directory if it doesn't exist
if (-not (Test-Path -Path "C:\Temp")) {
    New-Item -Path "C:\Temp" -ItemType Directory
}

# Download the .NET 8 runtime installer
try {
    Invoke-WebRequest -Uri $dotnetInstallerUrl -OutFile $installerPath
    Write-Log "Downloaded .NET 8 runtime installer."
} catch {
    Write-Log "Failed to download .NET 8 runtime installer: $_"
    exit 1
}

# Install the .NET 8 runtime
try {
    Start-Process -FilePath $installerPath -ArgumentList "/quiet", "/norestart" -Wait
    Write-Log "Installed .NET 8 runtime."
} catch {
    Write-Log "Failed to install .NET 8 runtime: $_"
    exit 1
}

# Verify the installation
try {
    $dotnetVersion = & "C:\Program Files\dotnet\dotnet.exe" --list-runtimes | Select-String "Microsoft.NETCore.App 8.0"
    if ($dotnetVersion) {
        Write-Log "Verified .NET 8 runtime installation: $dotnetVersion"
    } else {
        Write-Log "Failed to verify .NET 8 runtime installation."
        exit 1
    }
} catch {
    Write-Log "Failed to verify .NET 8 runtime installation: $_"
    exit 1
}

# End logging
Write-Log "Script execution completed."