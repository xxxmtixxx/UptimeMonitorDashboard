# Define the MonitorClients directory
$monitorClientsDirectory = "C:\Temp\MonitorClients"

# Path to the CSV file
$csvFilePath = Join-Path -Path $monitorClientsDirectory -ChildPath "clients.csv"

# Path to the HTML dashboard file
$dashboardFilePath = Join-Path -Path $monitorClientsDirectory -ChildPath "dashboard.html"

# Function to ping a client
function Test-ClientConnection {
    param ([string]$ipOrDomain)
    
    try {
        # First, check if local internet connection is up by pinging 8.8.8.8
        $googlePing = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue
        if (-not $googlePing) {
            return "Local Internet Down"
        }

        # Ping the client
        $clientPing = Test-Connection -ComputerName $ipOrDomain -Count 1 -Quiet -ErrorAction SilentlyContinue
        if ($clientPing) {
            return "Online"
        } else {
            return "Offline"
        }
    } catch {
        return "Offline"
    }
}

# Function to update the dashboard
function Update-Dashboard {
    # Re-read the CSV file each time this function is called
    $clients = Import-Csv -Path $csvFilePath | Sort-Object Client
    $dashboardContent = @"
<html>
<head>
    <meta http-equiv='refresh' content='30'>
    <style>
        .dark-mode {
            background-color: #333;
            color: #fff; /* This sets the text color to white */
            border-color: #fff; /* This sets the border color to white */
        }
        .dark-mode table {
            border-color: #fff; /* This sets the table border color to white */
        }
    </style>
</head>
<body>
<h1>Uptime Monitor</h1>
<button id='darkModeToggle' style='margin-bottom: 20px;'>Toggle Dark Mode</button>
<table border='1'>
<tr><th>Client</th><th>IP/Domain</th><th>Status</th></tr>
"@

    foreach ($client in $clients) {
        $clientName = $client.Client
        $ipOrDomain = $client.IPOrDomain
        $status = Test-ClientConnection -ipOrDomain $ipOrDomain
        $color = switch ($status) {
            "Online" { "Green" }
            "Offline" { "Red" }
            "Local Internet Down" { "Orange" }
        }
        $dashboardContent += "<tr><td>$clientName</td><td>$ipOrDomain</td><td style='background-color:$color;'>$status</td></tr>`n"
    }

    if ($status -eq "Local Internet Down") {
        $dashboardContent += "<h2 style='color:red;'><b>Local Internet is Down</b></h2>"
    }

    $dashboardContent += @"
</table>
<script>
document.getElementById('darkModeToggle').addEventListener('click', function() {
    document.body.classList.toggle('dark-mode');
    localStorage.setItem('dark-mode', document.body.classList.contains('dark-mode'));
});

// On page load, check if 'dark-mode' is in localStorage and apply it
window.onload = function() {
    if (localStorage.getItem('dark-mode') === 'true') {
        document.body.classList.add('dark-mode');
    }
};
</script>
</body>
</html>
"@
    # Use the full path to the dashboard file
    Set-Content -Path $dashboardFilePath -Value $dashboardContent
}

# Main loop to continuously check the clients
while ($true) {
    Update-Dashboard
    Start-Sleep -Seconds 30
}
