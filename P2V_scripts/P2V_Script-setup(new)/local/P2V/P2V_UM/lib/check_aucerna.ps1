$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir\P2V_include.ps1"

#-------------------------------------------------
#----- start main part

P2V_header -app $My_name -path $My_path 

$output_path = $output_path_base + "\$My_name"
$outfile     = $output_path + "\aucerna.csv"
createdir_ifnotexists($output_path)

$consultants=Get-ADUser -Filter { (EmailAddress -like "*aucerna.com") -or (EmailAddress -like "*quorumsoftware.com")} -properties * |
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


$consultants|select Givenname,surname,samaccountname, emailaddress,Department,comment,description,lastlogon,accountExpires|format-table

# $resp=$consultants|select Givenname,surname,samaccountname, emailaddress,comment|Out-gridview -title "AUCERNA consultants"  -outputmode single
#$consultants|where {$($_.samaccountname) -eq $($resp.samaccountname)}|out-host

Delete-ExistingFile -file $outfile
$consultants|select Givenname,surname,samaccountname, emailaddress,Department,comment,description,lastlogon,accountExpires|Export-Csv -Path $outfile

$form1 -f "output written to [$outfile]"
P2V_footer -app $My_name
Read-Host "Press Enter to close the window"