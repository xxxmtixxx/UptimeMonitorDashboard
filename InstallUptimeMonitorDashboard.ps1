# Start the transcript
Start-Transcript -Path "C:\Temp\console.log" -Append

# Check for administrative privileges at the beginning of the script
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Output "This script must be run as an Administrator. Please re-run this script as an Administrator."
    return
}

# Define the URL of the ZIP file
$zipUrl = "https://github.com/xxxmtixxx/UptimeMonitorDashboard/archive/refs/heads/main.zip"

# Define the path where the ZIP file will be downloaded
$zipFilePath = "C:\Temp\main.zip"

# Download the ZIP file
Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath

# Define the path where the ZIP file will be extracted
$extractPath = "C:\Temp\MonitorClients"

# Create the destination directory if it doesn't exist
if (-not (Test-Path -Path $extractPath)) {
    New-Item -ItemType Directory -Path $extractPath | Out-Null
    Write-Output "Created directory: $extractPath"
} else {
    Write-Output "Directory already exists: $extractPath"
}

# Extract the ZIP file
Expand-Archive -Path $zipFilePath -DestinationPath $extractPath -Force

# Define the source path
$sourcePath = Join-Path -Path $extractPath -ChildPath "UptimeMonitorDashboard-main"

# Move the files to the destination directory
Move-Item -Path "$sourcePath\MonitorClients.ps1" -Destination $extractPath
if (-not (Test-Path -Path "$extractPath\MonitorClients.ps1")) {
    Write-Output "Failed to move MonitorClients.ps1 to $extractPath"
    return
}

Move-Item -Path "$sourcePath\clients.csv" -Destination $extractPath
if (-not (Test-Path -Path "$extractPath\clients.csv")) {
    Write-Output "Failed to move clients.csv to $extractPath"
    return
}

Write-Output "Moved files to $extractPath"

# Cleanup the extracted folder and ZIP file
Remove-Item -Path $sourcePath -Recurse -Force
Remove-Item -Path $zipFilePath -Force
Write-Output "Cleaned up the extracted folder and ZIP file"

# Check if Chocolatey is installed
$chocoPath = "C:\ProgramData\chocolatey"
if (Test-Path -Path $chocoPath) {
    Write-Output "Chocolatey is installed at: $chocoPath"
} else {
    Write-Output "Chocolatey is not installed, installing now..."
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        $chocoVersion = & choco -v
        Write-Output "Chocolatey installed successfully, version: $chocoVersion"
    } catch {
        Write-Output "Failed to install Chocolatey."
        return
    }
}

# Check if NSSM is installed
$nssmPath = "C:\ProgramData\chocolatey\bin\nssm.exe"
if (Test-Path -Path $nssmPath) {
    Write-Output "NSSM is installed at: $nssmPath"
    $nssmInstalled = $true
} else {
    Write-Output "NSSM is not installed."
    $nssmInstalled = $false
}

# Install NSSM if not installed
if (-not $nssmInstalled) {
    Write-Output "Installing NSSM now..."
    choco install nssm -y --verbose

    # Check if NSSM was installed correctly
    try {
        $nssmVersion = & choco list --local-only | findstr "nssm"
        if ($null -ne $nssmVersion) {
            Write-Output "NSSM installed successfully, version: $nssmVersion"
            $nssmInstalled = $true
        }
    } catch {
        Write-Output "Failed to install NSSM."
        return
    }
}

# Create the service
try {
    # Temporarily add Chocolatey to the PATH for this session
    $env:Path += ";C:\ProgramData\chocolatey\bin"

    $nssm = (Get-Command nssm).Source
    Write-Output "NSSM command path: $nssm"
    Write-Output "System PATH: $env:PATH"
    $serviceName = 'MonitorClients'
    $powershell = (Get-Command powershell).Source
    $scriptPath = 'C:\Temp\MonitorClients\MonitorClients.ps1'
    $arguments = '-ExecutionPolicy Bypass -NoProfile -File "{0}"' -f $scriptPath

    & $nssm install $serviceName $powershell $arguments
    Write-Output "Created service: $serviceName"

    # Start the service
    Start-Service -Name $serviceName
    Write-Output "Started service: $serviceName"
} catch {
    Write-Output "Could not create or start service: $serviceName. Error: $_"
}

# Define the share name
$shareName = "MonitorClients"

# Check if the share exists
if (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue) {
    # Remove the existing share
    Remove-SmbShare -Name $shareName -Confirm:$false
}

# Share the folder
New-SmbShare -Name $shareName -Path $extractPath -FullAccess Administrator -Confirm:$false
Write-Host "Shared folder: $extractPath with share name: $shareName"

# Grant read access to Authenticated Users
Grant-SmbShareAccess -Name $shareName -AccountName "Authenticated Users" -AccessRight Read -Confirm:$false
Write-Host "Granted read access to Authenticated Users for share: $shareName"

# Create a shortcut to the dashboard.html file on the Public Desktop
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:PUBLIC\Desktop\Uptime Monitor Dashboard.lnk")

# Get the hostname
$hostname = [System.Net.Dns]::GetHostName()

# Set the TargetPath of the shortcut to the shared path of the dashboard.html file
$Shortcut.TargetPath = "file://$hostname/MonitorClients/dashboard.html"
$Shortcut.Save()

Write-Output "Created shortcut to dashboard.html on the Public Desktop."

# Stop the transcript at the end of the script
Stop-Transcript
