# Uptime Monitor Dashboard

![image](https://github.com/user-attachments/assets/c12355e9-72c0-4829-86db-7da66954c9ca)

## Description
The Uptime Monitor Dashboard is a simple yet powerful PowerShell-based tool, designed to monitor the uptime status of multiple IPs/domains at once. This tool does not require a webserver and continuously checks the status of clients listed in the CSV file, updating an HTML dashboard accordingly. The dashboard, which is shared via SMB, can be easily accessed from other Windows machines on the same network, making this tool lightweight and easy to deploy.

## Features
- **Simplicity**: The tool operates on a "red for down, green for up" principle, allowing you to see the status of all clients at a glance.
- **CSV File**: The tool uses a CSV file for client data input. You simply need to update the CSV file with the client name and IP/domain name.
- **Internet Connection Verification**: The tool verifies your internet connection and notifies you on the dashboard if it's not connected, helping to avoid false positives.
- **Continuous Monitoring**: The tool continuously monitors the status of each client listed in the CSV file and updates their status on the dashboard.
- **HTML Dashboard**: The status of each IP/domain is displayed on an HTML dashboard, which is automatically updated every 30 seconds.
- **SMB Share**: The HTML dashboard is shared via SMB, making it accessible from other Windows machines on the same network.
- **Shortcut Creation**: A shortcut to the dashboard is created on the Public Desktop for easy access.
- **Installer and Uninstaller Scripts**: The tool comes with PowerShell scripts to install and uninstall the tool. Both scripts create a log file at `C:\Temp\console.log` for troubleshooting purposes.

## CSV File
The CSV file (`clients.csv`) is located in the `C:\Temp\MonitorClients` directory. This file contains a list of clients to be monitored. Each client should be represented by a row in the CSV file with the following columns:
- `Client`: The name of the client.
- `IPOrDomain`: The IP address or domain name of the client.

You can modify the CSV file to add, remove, or change clients. The changes will be reflected on the dashboard the next time it is updated.

## Installation
To install the Uptime Monitor Dashboard, run the installer script with administrative privileges. The installer script performs the following actions:
- Downloads a ZIP file from a specified URL and extracts it to a specified directory.
- Checks if Chocolatey and NSSM are installed, and installs them if they are not.
- Creates a service to run the monitoring script.
- Shares the directory containing the HTML dashboard via SMB.
- Creates a shortcut to the dashboard on the Public Desktop.
- Logs all actions to `C:\Temp\console.log`.

## Uninstallation
To uninstall the Uptime Monitor Dashboard, run the uninstaller script with administrative privileges. The uninstaller script performs the following actions:
- Stops the service created by the installer script.
- Deletes the service.
- Removes the SMB share.
- Deletes the directory containing the HTML dashboard and the monitoring script.
- Deletes the shortcut from the Public Desktop.
- Logs all actions to `C:\Temp\console.log`.
