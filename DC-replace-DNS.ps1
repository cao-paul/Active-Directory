param(
	[Parameter(Position=0,Mandatory=$true)]
	$domain = "",
	$serveroff = "",
	$ipoff = ""
	)

Write-Host "***** Decommissioned server *****"
if ($serveroff){
	Write-Host `t "Server :" $serveroff
	$ip = Resolve-DnsName $serveroff -Type A -ErrorAction Ignore -WarningAction SilentlyContinue
	$ipoff = $ip.IPAddress
	if (!$ip){
		Write-Host `t "Unable to resolve DNS :" $serveroff	-ForegroundColor Red
		Write-Host `t "Restart the script with -ipoff" -ForegroundColor Red
		Write-Host `t "Script terminated" `n
		Break
		}
	}
Write-Host `t "IPv4 :" $ipoff `n

$ns = Resolve-DnsName -Name $domain
$dcdomain = Get-ADDomainController -DomainName $domain -Discover
$dc = Invoke-Command -ComputerName $domaindc.HostName -ScriptBlock{Get-ADDomainController -Filter *}

$dnsdc = foreach ($dns in $dc){
	Get-DnsClientServerAddress -InterfaceAlias Production -AddressFamily IPv4 -CimSession $dns.hostname
	}

$dnsall = @()
$dnsall += $dnsdc.ServerAddresses

$find = $dnsdc | ? {$_.ServerAddresses -contains $ipoff}

Write-Host "***** Domain AD *****"
Write-Host `t "Domain :" $domain `n
Write-Host `t "Number of DC :" $dcroot.count
Write-Host `t "Sample DC :" ($dcroot | random).HostName

Write-Host "***** 5 DNS less used *****"
$dnsall | group | sort count | select Count,Name -First 5 | ft

if ($ns.count -le 4){
	Write-Host `t "Number of NS too low" -ForegroundColor Red
	Write-Host `t "Make parameter corrections by hand"
	Write-Host `t "Script terminated" `n
	Break
	}else{
	Write-Host `t "Number of NS sufficient" -ForegroundColor Green `n
	}

Write-Host "***** DNS extraction loop *****"

if (!$find){
	Write-Host `t "No DC server with DNS :" $ipoff
	Write-Host `t "Script terminated" `n
	Break
	}else{
	Write-Host `t $find.count "DC server with DNS :" $ipoff `n
	}

foreach ($srv in $find){
	Write-Host `t $srv.PSComputerName -ForegroundColor Yellow
	$newdns = @()
	$newns = $dnsall | group | sort count | select -First 5 | ? {$_.Name -notin $srv.ServerAddresses -and $_.Name -ne (Resolve-DnsName $srv.PSComputerName).IPAddress}
	
	foreach ($dns in $srv.ServerAddresses){
			if ($dns -ne $ipoff){
				$newdns += $dns
			}else{
				$newdns += $newns.Name | random
			}
		}
		Write-Host `t "Change DNS settings"
		Set-DnsClientServerAddress -InterfaceAlias Production -CimSession $srv.PSComputerName -ServerAddresses $newdns
		Write-Host `n `t "Actual DNS :" $srv.ServerAddresses
		Write-Host `t "New DNS applicated :" $newdns -ForegroundColor Green
		
		Write-Host `n `t "Check new DNS"
		$check = Get-DnsClientServerAddress -AddressFamily IPv4 -InterfaceAlias Production -CimSession $srv.PSComputerName
		Write-Host `t "DNS applicated :" $check.ServerAddresses `n
	}

Write-Host "***** End of treatment *****"
