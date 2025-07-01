

$consultants=Get-ADUser -Filter { (EmailAddress -like "*aucerna.com") -or (EmailAddress -like "*quorumsoftware.com") } -properties * |
select  Givenname, 
		surname,
		SamAccountName, 
		EmailAddress, 
		userPrincipalName,
		Department,
		lastLogon,
		lastLogonTimestamp,
		accountExpires,
		description

$consultants|%{ $_.lastLogon=[datetime]::FromFileTime($_.lastlogon).tostring('yyyy-MM-dd HH:mm:ss');
				$_.lastLogonTimestamp=[datetime]::FromFileTime($_.lastlogonTimestamp).tostring('yyyy-MM-dd HH:mm:ss');
				$_.accountExpires=[datetime]::FromFileTime($_.accountExpires).tostring('yyyy-MM-dd HH:mm:ss');

}



$consultants|format-table