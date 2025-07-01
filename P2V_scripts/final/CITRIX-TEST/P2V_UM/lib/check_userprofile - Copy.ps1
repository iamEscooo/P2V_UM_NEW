#-----------------------------------------
# check_userprofile 
#
#  name:   check_userprofile.ps1 
#  ver:    1.0
#  author: M.Kufner
#
# retrieve account settings for specific user 
# $P2Vgroups = true (default)/false   - show P2V AD group memberships
#-----------------------------------------
param(
  [string] $xkey      = "",
  [string] $workdir   = "",
  [bool]   $P2Vgroups = $True,
  [bool]   $P2Vtenants = $True,
  [bool]   $get_lic   = $True
   )
#-------------------------------------------------
$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir\P2V_include.ps1"

#  Set config variables
$output_path = $output_path_base + "\$My_name"

$license     = @("n/a","light license","PetroVR license","heavy license","array exeeded")

#-------------------------------------------------
$global:form4      ="|  {0,-18} {1,-16}{2,-16} {3,-24} |"
#----- start main part

P2V_header -app $My_name -path $My_path 
createdir_ifnotexists($output_path)
While ($result= get_AD_user($xkey))
{
  #----- check whether xkey exists in AD and retrieve core information
     $user =  $result.Name
  # $result=Get-ADUser -Filter {Name -like $user} -properties *|select Name,GivenName,Surname,UserPrincipalName,SamAccountName,EmailAddress,Department,Enabled,PasswordExpired ,LockedOut,lockoutTime, HomeDirectory 
  if(! $result) {$form_err -f "[ERROR]", " !! [$user] does not exist in Active Directory !!"   }	
  else
  { 
    $linesep
    $form1 -f  "Active Directory information for $($result.displayName)"
    $linesep
	
	P2V_print_object($result)
		   
    if ($P2vgroups)
    {
      #----- check whether xkey is member of ADgroups of P2V
      $linesep
	  $form1 -f  "P2V AD group memberships for $($result.displayName)"
	  $form1 -f ""
      
      $user_lic = 0;
      foreach ($i in import-csv $adgroupfile)
      {
	    $i.ADgroup=$($i.ADgroup).trim()
	     if ($check_group = Get-ADGroup -LDAPFilter "(SAMAccountName=$($i.ADgroup))")
		 {
            if (Get-ADGroupMember -Identity $($i.ADgroup)|where {$($_.SamAccountName) -eq $($result.SamAccountName)}) 
            { 
              $form1 -f $i.ADgroup 
              if ($get_lic) { $user_lic = ($user_lic, $($i.Lic_type)|Measure -Max).Maximum }	 
            }
	     } else 
		 {
		   # $i.ADgroup does not exist ..
		   #  error ? 
		   # $form_err -f "[ERROR]","Hmm - seems that [$($i.ADgroup)] does either not exist or is not reachable"
		 }
      } 
      # get all AD-groups for specific useraccount
      #$groups= Get-ADPrincipalGroupMembership $user|select name |where { $($_.name) -like "*P2V*" -or ($($_.name) -like "*PetroVR*")}
      #$groups |format-table| out-host 
      
      if ($get_lic)  
      {
      $linesep   
         $form1 -f "license for $($result.displayName): $($license[$user_lic])"
      }
    }
	$linesep
	$form1 -f "checking PS tenant for user $($result.displayName)"
	$form1 -f ""
	$form4 -f "tenant" ,"Deactivated","AccountLocked","(ID)/Lastlogin"              		  
	#$form2_1 -f "tenant","login","islocked","isdeactivated",
	if ($P2Vtenants)
	{
	    $selected_tenants= @{}
        $t_list= @{}
        $all_tenants =import-csv $tenantfile 
        $all_tenants |% {$t_list[$($_.tenant)]=$_}
        if (!$all_tenants) {$form_err -f "[ERROR]"," tenantfile $tenantfile does not exist"; exit }
     
            #|select system,tenant, ServerURL |out-gridview -Title "select tenant(s)" -outputmode multiple

#  add baseauthstring to tenant
         #$t_list|format-table
		 
		 
        #$t_list|%{ $b=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t_list[$_.tenant].name, $t_list[$_.tenant].API)));`
        #          $t_list[$_.tenant]| Add-Member -Name 'base64AuthInfo'  -Type NoteProperty -Value "$b" }
        
         
 
        foreach ($i in $t_list.keys)
		{
		  $t_sel=$t_list[$i]
		  #$form1 -f "--> $($t_sel.tenant) <--"
      	  $tenantURL      ="$($t_sel.ServerURL)/$($t_sel.tenant)"
          $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t_sel.name, $t_sel.API)))
          $API_URL        ="$tenantURL/PlanningSpace/api/v1/users" # w/o grouplist?
          $UPN            =$($result.UserPrincipalName)
		 		  
          $resp=Invoke-RestMethod -Uri $API_URL -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
          if (!$resp) {$form_err -f "[ERROR]", "cannot contact $tenant !" ;exit}
		  $resp_user=$resp|where-Object {($($_.authenticationMethod) -ne 'LOCAL' -and $_.logOnId -eq $UPN) } 
		  
		  if ($resp_user)
		  {
		    $resp_user|%{ $form4 -f "$($t_sel.tenant)" ,"[$($_.isDeactivated)]","[$($_.isAccountLocked)]", "$($_.id)/$($_.lastLogin)"              		  }
		  } else 
		  {
		    $form4 -f "$($t_sel.tenant)","","", "[no account]"
		  }
		  
		  
		  
		}
		
		
      $selected_tenants.name
      $selected_tenants.values|format-list|out-host
	
	
	
    
   }
  }
  $linesep


} # end while
P2V_footer -app $My_name
Read-Host "Press Enter to close the window"