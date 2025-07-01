$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir\P2V_include.ps1"

#-------------------------------------------------
#----- start main part

P2V_header -app $My_name -path $My_path 

$consultants=Get-ADUser -Filter { (EmailAddress -like "*aucerna.com")} -properties * |
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


$resp=$consultants|select Givenname,surname,samaccountname, emailaddress,comment|Out-gridview -title "AUCERNA consultants"  -outputmode single

$consultants|where {$($_.samaccountname) -eq $($resp.samaccountname)}|out-host

P2V_footer -app $My_name
Read-Host "Press Enter to close the window"