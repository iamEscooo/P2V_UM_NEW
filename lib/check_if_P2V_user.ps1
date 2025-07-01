

$group = 'dlg.WW.ADM-Services.P2V.access.production'  
$userlist= @()
$u_search =""
while ($u_search -ne "0") 
{
	$u_search =""
	while (!$u_search) { $u_search= Read-Host "Please enter user-searchstring (xkey): (0=exit)"}
	
	if ($u_search -ne "0") 
	{
		$userlist += $u_search
	}



}
$baselist=@()
$adlist = Get-ADGroupMember -Identity $group | select name |%{ $baselist +=$_.name}

foreach ($u in $userlist)
{
      
      if  ($baselist -contains $u){	  
	    write-output "$u"
	  } else {
	    #write-output "$u    -> NO"
	  }
}
	
	
	
