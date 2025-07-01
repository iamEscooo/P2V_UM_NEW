
Function P2V_update_user ($tenant , $user_profile , $changes)
{ # function to update existing user in P2V_tenant
  #
  $tenantURL      ="$($tenant.ServerURL)/$($tenant.tenant)"
  $base64AuthInfo ="$($tenant.base64AuthInfo)"
  $API_URL        ="$tenantURL/PlanningSpace/api/v1/users/$($user_profile.id)"
  $linesep        ="+-------------------------------------------------------------------------------+"
  $linesep
  "in function"
  $linesep
  out-host

  write-host "-->> tenant"  
  $tenant |format-list
  write-host "-->> user_profile"  
  $user_profile|format-list
  write-host "-->> changes"  
  $changes|format-table
   
   
  $body = ($changes|ConvertTo-Json)
  #$body = [System.Text.Encoding]::UTF8.GetBytes($body)
  
  # add [] around single change -otherwise API 500 error
  if ($($changes.count) -eq 1 ){ $body="[ $body ]" }  
  $linesep
  write-host "API-URL:  $API_URL"
    
  write-host "--"
  
  # pause
  
  # $result = Invoke-RestMethod -Uri $API_URL -Method PATCH -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ($body) -ContentType "application/json"
    
  # if ($result) {$rc="[DONE]"  ;$r=$true}
  # else         {$rc="[ERROR]" ;$r=$false} 
  
  $form_status -f $user_profile.displayName,$rc
  out-host	
	
  return $r
}

$AD_user=[PSCustomObject]@{
Givenname         = "Martin";
surname           = "Kufner";
SamAccountName    = "X449222";
EmailAddress      = "Martin.Kufner@omv.com";
comment           = "ACTIVE";
Department        = "EETE-P Petrotechnical AppStore";
lastlogon         = "2021-03-08 12:19:05";
accountExpires    = "9999-12-31 00:00:00";
UserPrincipalName = "Martin.Kufner@omv.com";
displayName       = "Kufner Martin (X449222)";
logOnId           = "Martin.Kufner@omv.com"
}
		
#----  user_profile PS                          ----
$PS_user=[PSCustomObject]@{
       id					= "5";
       logOnId              = "martin.kufner@omv.com";
       displayName 		    = "Kufner Martin (X449222)";
       description 		    = "EEDA-F Surface DDAM";
       isDeactivated 	 	= $False;
       isAccountLocked 	    = $False;
       authenticationMethod = "SAML2";
       useADEmailAddress    = $False;
       emailAddress         = "Martin.Kufner@omv.com"
}
#---------------------------------------------------

#----  tenant                                   ----
$tenant=[PSCustomObject]@{
       system         = "TEST";
       ServerURL      = "https://ips-test.ww.omv.com";
       tenant         = "P2V_PRODTEST";
       resource       = "Planningspace";
       name           = "FeedKey";
       API            = "API.FA357F3B277B445895F30102D20AD95D.FF34031B6BED646F836D85E597C2FF97";
       ADgroup        = "dlg.WW.ADM-Services.P2V.testusers";
       base64AuthInfo = "calculated string"
}
 $change_ops += [PSCustomObject]@{  
                       op     = "replace";
                       path   = "/displayName";
                       value  = "arme Sau"
					   }


P2V_update_user($tenant, $PS_user, $change_ops)
$linesep
P2V_update_user $tenant $PS_user $change_ops