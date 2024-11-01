$domain = Get-ADDomain
$childdomain = Get-DnsServerZoneDelegation -Name $domain.Forest -ComputerName $domain.InfrastructureMaster
$dcroot = Get-ADDomainController -Filter * -Server $domain.Forest
$nsroot = $dcroot.IPv4Address

Write-Host "***** Domaine AD *****"
Write-Host `t "Root domain :" $domain.Forest `n
Write-Host `t "Number of DC :" $dcroot.count
Write-Host `t "Sample DC :" ($dcroot | random).HostName
Write-Host `t "NS root :" -Foreground Green
$nsroot
Write-Host `n

Write-Host "***** Checking DNS forwarders of child domains *****"

foreach ($zone in ($childdomain | select ChildZoneName -Unique).ChildZoneName){
	Write-Host `t "Child domain :" $zone -Foreground Yellow
	$dcchild = Get-ADDomainController -Filter * -Server $zone -ErrorAction Ignore
	Write-Host `t "Domain DC :" $dcchild.count `n
	
	foreach ($srv in $dcchild){
		Write-Host `t $srv.Name -Foreground Yellow
		$nssrv = Get-DnsServerForwarder -ComputerName $srv.Name
		$nscheck = $nssrv.IPAddress.IPAddressToString | ? {$_ -notin $nsroot}
		if (!$nscheck){
			Write-Host `t "DNS Forwarder compliant"
			}else{
			Write-Host `t "DNS Forwader no compliant:"
			$nscheck
			}
		}
	Write-Host `t 
	}

Write-Host "***** End of treatment *****"
