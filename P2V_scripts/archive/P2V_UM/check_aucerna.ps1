

$consultants=Get-ADUser -Filter { (EmailAddress -like "*quorum*.com")} -properties * |
select  Givenname, 
		surname,
		SamAccountName, 
		EmailAddress, 
		userPrincipalName,
		comment,
		Department,
		distinguishedName,
		lastlogon,
		lastLogonTimestamp,
		accountExpires,
		description
		

$consultants|%{ $_.lastLogon=[datetime]::FromFileTime($_.lastlogon).tostring('yyyy-MM-dd HH:mm:ss');
				$_.lastLogonTimestamp=[datetime]::FromFileTime($_.lastlogonTimestamp).tostring('yyyy-MM-dd HH:mm:ss');
				$_.accountExpires=[datetime]::FromFileTime($_.accountExpires).tostring('yyyy-MM-dd HH:mm:ss');
				if ("$($_.distinguishedName)" -match "Deactivates") {$_.comment="DEACTIVATED"} else {$_.comment="ACTIVE"}
}



$consultants|Out-gridview -title "AUCERNA/Quorum consultants"  -outputmode single