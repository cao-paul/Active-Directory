param(
	[Parameter(Position=0,Mandatory=$true)]
	$domain = "",
	$serveroff = "",
	$ipoff = ""
	)

Write-Host "***** Decommissioned server *****"
if ($serveroff){
	Write-Host `t "Serverdown :" $serveroff
	$ip = Resolve-DnsName $serveroff -Type A -ErrorAction Ignore -WarningAction SilentlyContinue
	$ipoff = $ip.IPAddress
	if (!$ip){
		Write-Host `t "Résolution DNS impossible :" $serveroff	-ForegroundColor Red
		}
	}
Write-Host `t "IPv4 :" $ipoff `n

$ns = Resolve-DnsName -Name $domain
$dcdomain = Get-ADDomainController -DomainName $domain -Discover
$domainname = Get-ADDomain -Identity $domain
$dc = Invoke-Command -ComputerName $domaindc.HostName -ScriptBlock{Get-ADDomainController -Filter *}

Write-Host "***** Domaine AD *****"
Write-Host `t "Domaine :" $domain `n
Write-Host `t "Number of DC :" $dcroot.count
Write-Host `t "Sample DC :" ($dcroot | random).HostName

Write-Host "***** Site and Services Active Directory *****"

if (!$serveroff){
	Write-Host `t "Server not declared"
	Write-Host `t "Restart the script with -serveroff" `n -ForegroundColor Red
	}else{
	$findsite = @()
	$sitead = Get-ADReplicationSite -Filter * -Properties *
	$sitesrv = foreach ($site in $sitead){
		dsquery server -site $site.Name
		}
	foreach ($srv in $sitesrv){
		if ($srv  | ? {$_ -like "*$serveroff*"}){
			$findsite += $srv.Split(',')[2]
			}
		}
	if ($findsite){
		Write-Host `t "AD site with server :" $serveroff -ForegroundColor Red
		$findsite | select -Unique
		Write-Host `n
		}else{
		Write-Host `t "AD sites don't have the server :" $serveroff `n
		}
	}

Write-Host "***** Serveur DC - DNS Configuration *****"

if (!$ipoff){
	Write-Host `t "Unable to resolve DNS :" $serveroff
	Write-Host `t "Restart the script with -ipoff" `n -ForegroundColor Red
	}else{
	$dcdns = foreach ($dns in $dc){
		Get-DnsClientServerAddress -InterfaceAlias Production -AddressFamily IPv4 -CimSession $dns.hostname
		}
	$dcfind = @()
	foreach ($srvdns in ($dcdns | ? {$_.ServerAddresses -contains $ipoff})){
		if ($srvdns | ? {$_.ServerAddresses -contains $ipoff}){
			$dcfind += $srvdns.PSComputerName
			}
		}

	if ($dcfind){
		Write-Host `t "DC server with DNS :" $ipoff -ForegroundColor Red
		$dcfind
		Write-Host `n
		}else{
		Write-Host `t "No DC server with DNS :" $ipoff `n
		}
	}

Write-Host "***** Domain Zone - Name Server Record *****"

if (!$ipoff){
	Write-Host `t "Unable to resolve DNS :" $serveroff
	Write-Host `t "Restart the script with -ipoff" `n -ForegroundColor Red
	}else{
	if ($ns | ? {$_.IPAddress -eq $ipoff}){
		Write-Host `t "Presence of an NS record" $ipoff "on the domain" $domain -ForegroundColor Red `n
		}else{
		Write-Host `t "No presence of an NS record" $ipoff "on the domain" $domain `n
		}
	}

Write-Host "***** End of treatment *****"
