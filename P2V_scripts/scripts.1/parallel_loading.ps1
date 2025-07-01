$ADgroupLoadList =@("dlg.WW.ADM-Services.P2V.access.production","dlg.WW.ADM-Services.P2V.access.test","dlg.WW.ADM-Services.P2V.access.update","dlg.WW.ADM-Services.P2V.access.training")

$startdate=(get-date -format "dd/MM/yyyy HH:mm:ss")

ForEach ($g in $ADgroupLoadList)
	{
		
		if ($check_group = Get-ADGroup -Identity $g )
	 	{
			write-host "> $g found - start loading"
    	
			$l_userlist=@()

            
            start-job -ScriptBlock {
			$loc_userlist=Get-ADGroupMember -Identity $using:g|Get-ADUser -properties * |
   		select  Name, 
		        Givenname, 
				surname,
				SamAccountName,
				UserPrincipalName, 
				EmailAddress, 
				Department,
				description,
			    Enabled
		  
			$loc_userlist|% {$l_userlist+=@($_.SAMAccountName)}
             $result= @{}
	        $result[$using:g]=$l_userlist
		$result|ConvertTo-Json
            }
           }
    }
write-output "------ JOBS     ---------"
    
get-job|ft


write-output "------ RESULT   ---------"

while (Get-job)
{
   Get-job -HasMoreData $true |%{$_;  Receive-Job -Job $_ -Wait -AutoRemoveJob               }
}


$enddate=(get-date -format "dd/MM/yyyy HH:mm:ss")
write-output "------ DURATION ---------"
write-output "[$startdate] -  [$enddate]"  