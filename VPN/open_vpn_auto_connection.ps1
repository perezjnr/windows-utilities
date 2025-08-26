<# 
Description: This script checks the current network connection and connects to a OPENVPN server on windows computers
if not connected to a specified home network.
It also disconnects from the OPENVPN if connected to the home network or if there is no internet connection.
The script logs events to the Windows Event Log for monitoring purposes.

Requirements: PowerShell 5.1 or later, OpenVPN GUI installed and configured.

Author: Perez O.

Date: 2024-06-20

Version: 1.0

Note: Ensure OpenVPN GUI is installed and configured with the specified VPN profile.
Configuration Variables (Adjust these as needed)
Define your home network IP prefix and SSID

NOTE: 
script must be run with elevated privileges (Run as Administrator)
    add to Task Scheduler with highest privileges
    Triggers: 1. At log on of any user
            2. on event 1000 network profile change (Microsoft-Windows-NetworkProfile/Operational)
    Action: Start a program -> Program/script: powershell.exe
    Add arguments (optional): -File "C:\Path\To\Your\Script\open_vpn_auto_connection.ps1"
    e.g -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Path\To\Your\Script\open_vpn_auto_connection.ps1"
#>

# Configuration Variables
$homeIPPrefix = "192.168.1.20"      # Adjust to match your home network
$networkName = "Mynetwork"         # Replace with your actual network name/SSID
$vpnConfigName = "my_vpn_config_name" # Replace with your actual VPN configuration name
# Path to OpenVPN GUI executable
$openvpnGuiPath = "C:\Program Files\OpenVPN\bin\openvpn-gui.exe" # Adjust if OpenVPN GUI is installed in a different location
$connectedNetwork = ""
$logSource = "VPNPowerShell" # Custom source name
$logName = "OpenVPNAutoConnect" # Custom log name
$maxRetries = 5 # Number of retries for internet connection check
$delaySeconds = 10 # Delay between retries in seconds


# Create event log source if it doesn't exist
if (-not [System.Diagnostics.EventLog]::SourceExists($logSource)) {
    New-EventLog -LogName $logName -Source $logSource
}
#add message to windows log
function addLogMessage()
{
    param($message)


    Write-EventLog -EventId 1992 -LogName OpenVPNAutoConnect -Message "$message" -Source $logSource -EntryType Information
    
}
#Fetch all available connections that are up and not Hyper interfaces
function getConnections{
    addLogMessage("Fetching Networks...")
    $connections =Get-NetIPConfiguration | Where-Object {$nUll -ne $_.IPv4Address -and $_.NetAdapter.Status -eq 'Up' -and $_.InterfaceAlias -notlike "vEthernet*"}
	return $connections
}
#fetch connections
$connections = getConnections

#Check if connected to VPN 
function vpnCheck{
    $connections = getConnections


    $connection = $connections | Where-Object{$_.InterfaceAlias -like "OpenVPN*"} 
     $entry = $connection | Select-Object -ExpandProperty IPv4Address
     $connectedNetwork = $connection.NetProfile.Name
     $ipAddress = $entry.IPAddress
     $dnsServers = $connection.DnsServer.ServerAddresses
     $interface = $entry.InterfaceAlias
    	
    #Check if connected to VPN by looking for OpenVPN interface and validating IP and DNS
    if($null -ne $connection -and ($connection.DnsServer.ServerAddresses | Where-Object{ $_ -notlike "$homeIPPrefix*" }).Count -eq 0)
    {
        addLogMessage("Connected to VPN: $connectedNetwork `nIP:$ipAddress `nDNS Servers:$dnsServers `nInterface:$interface")
        return 1
    }
    else
    {
        return 0
    }
}

#Check if connected to home network 
# Return 1 if connected to home network
# Return 2 if connected to VPN
# Return 0 if not connected to home network or VPN
function checkConnectedNetwork{
    param($connections)
    
    foreach ($connection in $connections) 
    {
     $entry = $connection | Select-Object -ExpandProperty IPv4Address
     $connectedNetwork = $connection.NetProfile.Name
     $ipAddress = $entry.IPAddress
     $dnsServers = $connection.DnsServer.ServerAddresses
     $interface = $entry.InterfaceAlias

     if ($connection.NetProfile.Name -eq $networkName -and ($entry.IPAddress -like "$homeIPPrefix*" -and ($connection.DnsServer.ServerAddresses | Where-Object{ $_ -notlike "$homeIPPrefix*" }).Count -eq 0)) {
            
            addLogMessage("Connected to Home network: $connectedNetwork `nIP:$ipAddress `nDNS Servers:$dnsServers `nInterface:$interface")
            return 1
        }
        elseif((vpnCheck) -eq 1)
        {
            return 2
        }
        else
        {
            
            addLogMessage("VPN Disconnected `nConnected Network: $connectedNetwork `nIP:$ipAddress `nDNS Servers:$dnsServers `nInterface:$interface")
            return 0
        }
    }
}


#Check for internet connection by pinging a reliable host (Google DNS)
# Returns $true if internet is available, otherwise $false
function internetConnectionCheck{

    $internetConnected = $false
    $testHost = "8.8.8.8"
	# Retry loop
	for ($i = 1; $i -le $maxRetries; $i++) {
        addLogMessage("Checking internet connectivity...")

		if (Test-Connection -ComputerName $testHost -Count 2 -Quiet) {
            addLogMessage("Internet is available.")            
			$internetConnected = $true
			break
		} else {
            addLogMessage("No internet connection. Ping $i `nRetrying in $delaySeconds seconds...") 
			Start-Sleep -Seconds $delaySeconds
			$internetConnected = $false
    
		}
	}
    return $internetConnected
}

#connect to open vpn if not connected to home network or vpn already connected
# Also checks for internet connectivity before attempting to connect
# Retries connection check a specified number of times
# Logs each step to the Windows Event Log
function connectVpn {
    param($connections)
    
    if((vpnCheck) -eq 0 -and (internetConnectionCheck))
    {
        addLogMessage("Connecting to VPN...")

        Start-Process -FilePath $openvpnGuiPath -ArgumentList "--command connect $vpnConfigName"
		Start-Sleep -Seconds 15
		for($i = 1; $i -le $maxRetries; $i++)
		{
            addLogMessage("Checking VPN Status...")
			$check = vpnCheck
			if( $check -eq 1 -and (internetConnectionCheck))
			{
				break;
			}
			else {
				Start-Sleep -Seconds 15
			}
			
		}
    }
    
}

#Disconnect from all open vpn connections if connected to home network or no internet connection
# Logs the disconnection event to the Windows Event Log
# Also checks the connection status after disconnection
function disconnectVpn {        
    addLogMessage("Disconnecting All Open VPN Connection...")
    Start-Process -FilePath $openvpnGuiPath -ArgumentList "--command disconnect_all"
    checkConnectedNetwork($connections)
}


# Main Logic
# Check current network status and decide to connect or disconnect VPN

# Fetch current connections
$connectCheck = checkConnectedNetwork($connections)

# Decide action based on current connection status
# 0 = Not connected to home network or VPN
# 1 = Connected to home network
# 2 = Connected to VPN
# Connect to VPN if not connected to home network or VPN
# Disconnect from VPN if connected to home network or no internet connection
if($connectCheck -eq 0)
{
    connectVpn($connections)
}
elseif($connectCheck -eq 1 -or ((internetConnectionCheck) -eq $false -and $connectCheck -eq 2))
{
    disconnectVpn
}

    