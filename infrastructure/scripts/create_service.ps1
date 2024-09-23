param (
    [string]$DownloadedFile,          # Path to the downloaded setup script (setup_script.ps1)
    [string]$DestinationFolder = "C:\scripts",  # Directory to copy the file to (default C:\scripts)
    [string]$Username,                # Username to run the service
    [string]$Password,                # Password for the user
    [string]$storageAccountName,
    [string]$storageAccountKey,
    [string]$fileshareName,
    [string]$storageAccountConnectionString,
    [bool]$createTask = $false     # Flag to create a scheduled task to run the script (default false). If true it requires the user to be logged in once before

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
    $taskName = "Bootstrapping"

    # Check if the scheduled task already exists
    $taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

    if($createTask -eq $false){
        Write-Log "Scheduled Task creation is disabled. Skipping creation." "INFO"
        Write-Log "Creating shortcut to be manually run." "INFO"
        $shortcutPath = "$DestinationFolder\RunBootstrapping.lnk"
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($shortcutPath)
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$DestinationFile`" -storageAccountName `"$storageAccountName`" -storageAccountKey `"$storageAccountKey`" -fileShareName `"$fileshareName`" -storageAccountConnectionString `"$storageAccountConnectionString`""
        $Shortcut.Save()
        Write-Log "Shortcut created at $shortcutPath" "INFO"
        exit 0
    }

    if ($taskExists) {
        Write-Log "Scheduled Task $taskName already exists. Skipping creation." "INFO"
        exit 0
    } else {
    $triggerAtStartup = New-ScheduledTaskTrigger -AtStartup
    $triggerAtLogon = New-ScheduledTaskTrigger -AtLogOn -User $Username
    $action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$DestinationFile`" -storageAccountName `"$storageAccountName`" -storageAccountKey `"$storageAccountKey`" -fileShareName `"$fileshareName`" -storageAccountConnectionString `"$storageAccountConnectionString`""
    
    # Register the task
    Register-ScheduledTask -TaskName $taskName -Trigger $triggerAtStartup,$triggerAtLogon -Action $action -User "$env:COMPUTERNAME\$Username" -Password $Password -RunLevel Highest
    
    Write-Log "Scheduled Task $taskName has been created to run $DestinationFile as $env:COMPUTERNAME\$Username." "INFO"
    }
}catch{
    Write-Log "Failed to create scheduled task: $_" "ERROR"
    exit 1
}