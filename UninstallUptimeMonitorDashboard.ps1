# Start the transcript
Start-Transcript -Path "C:\Temp\console.log" -Append

# Check for administrative privileges at the beginning of the script
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Output "This script must be run as an Administrator. Please re-run this script as an Administrator."
    return
}

# Define the service name
$serviceName = 'MonitorClients'

# Stop the service if it's running
try {
    Stop-Service $serviceName -ErrorAction Stop
    Write-Output "Stopped service: $serviceName"
    
    # Wait for the service to fully stop
    while ((Get-Service $serviceName -ErrorAction SilentlyContinue).Status -eq 'Running') {
        Start-Sleep -Seconds 2
    }
    Write-Output "Service $serviceName is fully stopped."
} catch {
    Write-Output "Could not stop service: $serviceName. It may not exist."
}

# Delete the service
try {
    $nssm = (Get-Command nssm).Source
    & $nssm remove $serviceName confirm
    Write-Output "Removed service: $serviceName"
    
    # Wait for the service to be fully deleted
    while (Get-Service $serviceName -ErrorAction SilentlyContinue) {
        Start-Sleep -Seconds 2
    }
    Write-Output "Service $serviceName is fully deleted."
} catch {
    Write-Output "Could not remove service: $serviceName. It may not exist, or NSSM may not be installed."
}

# Define the destination path
$destinationPath = "C:\Temp\MonitorClients"

# Define the share name
$shareName = 'MonitorClients'

# Remove the SMB share if it exists
if (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue) {
    Remove-SmbShare -Name $shareName -Force
    Write-Output "Removed SMB share: $shareName"
} else {
    Write-Output "SMB share does not exist: $shareName"
}

# Delete the destination directory if it exists
if (Test-Path -Path $destinationPath) {
    Remove-Item -Path $destinationPath -Recurse -Force
    Write-Output "Deleted directory: $destinationPath"
} else {
    Write-Output "Directory does not exist: $destinationPath"
}

# Delete the shortcut from the Public Desktop
$shortcutPath = "$env:PUBLIC\Desktop\Uptime Monitor Dashboard.lnk"
if (Test-Path -Path $shortcutPath) {
    Remove-Item -Path $shortcutPath -Force
    Write-Output "Deleted shortcut from the Public Desktop."
} else {
    Write-Output "Shortcut does not exist on the Public Desktop."
}

# Stop the transcript at the end of the script
Stop-Transcript
