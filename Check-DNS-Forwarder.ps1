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
	$dcdown = @()
	$dcup = @()
	foreach ($dcsrv in $dcchild){
		if (Get-ADComputer -Identity $dcsrv.Name -Properties * -Server $dcsrv.Domain | ? {$_.MemberOf -like "*ADAAD_DSC_DC_EXCLUDE_GU*"}){
			$dcdown += $dcsrv
			}else{
			$dcup += $dcsrv
			}
		}
	Write-Host `t "DC du domaine :" $dcup.count `n
	
	foreach ($upsrv in $dcup){
		Write-Host `t $upsrv.Name -Foreground Yellow
		$nsupsrv = Get-DnsServerForwarder -ComputerName $upsrv.Name
		$nscheck = $nsupsrv.IPAddress.IPAddressToString | ? {$_ -notin $nsroot}
		if (!$nscheck){
			Write-Host `t "DNS Forwarder conforme"
			}else{
			Write-Host `t "DNS Forwader non conforme :"
			$nscheck
			}
		}
	Write-Host `t 
	}

Write-Host "***** End of treatment *****"
