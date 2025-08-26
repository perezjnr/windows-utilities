$homeIPPrefix = "10.0.2."       # Adjust to match your home network
$networkName = "PeeJayTech"         # Replace with your actual SSID
$vpnConfigName = "PJT-Home-perez"
$openvpnGuiPath = "C:\Program Files\OpenVPN\bin\openvpn-gui.exe"
$checkInterval = 5  # seconds
$connectedNetwork = ""
$logSource = "VPNPowerShell"
$logName = "OpenVPNAutoConnect"
$maxRetries = 5
$delaySeconds = 10


# Register the source if it doesn't exist
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
    $connections =Get-NetIPConfiguration | Where-Object {$_.IPv4Address -ne $nUll -and $_.NetAdapter.Status -eq 'Up' -and $_.InterfaceAlias -notlike "vEthernet*"}
	return $connections
}
#fetch connections
$connections = getConnections


#check if already connected to vpn 
function vpnCheck{
    $connections = getConnections


    $connection = $connections | Where-Object{$_.InterfaceAlias -like "OpenVPN*"}
     $entry = $connection | Select-Object -ExpandProperty IPv4Address
     $connectedNetwork = $connection.NetProfile.Name
     $ipAddress = $entry.IPAddress
     $dnsServers = $connection.DnsServer.ServerAddresses
     $interface = $entry.InterfaceAlias
    	
	
    #check for vpn connection
    if($connection -ne $null -and ($connection.DnsServer.ServerAddresses | Where-Object{ $_ -notlike "$homeIPPrefix*" }).Count -eq 0)
    {
        addLogMessage("Connected to VPN: $connectedNetwork `nIP:$ipAddress `nDNS Servers:$dnsServers `nInterface:$interface")
        return 1
    }
    else
    {
        return 0
    }
}

#Go thorugh the connected networks and decide for vpn connection or not
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
#Check if the computer has internet connection
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

#Connect to VPN Server
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

#disconnect from open vpn
function disconnectVpn {        
    addLogMessage("Disconnecting All Open VPN Connection...")
    Start-Process -FilePath $openvpnGuiPath -ArgumentList "--command disconnect_all"
    checkConnectedNetwork($connections)
}



$connectCheck = checkConnectedNetwork($connections)

if($connectCheck -eq 0)
{
    connectVpn($connections)
}
elseif($connectCheck -eq 1 -or ((internetConnectionCheck) -eq $false -and $connectCheck -eq 2))
{
    disconnectVpn
}

    