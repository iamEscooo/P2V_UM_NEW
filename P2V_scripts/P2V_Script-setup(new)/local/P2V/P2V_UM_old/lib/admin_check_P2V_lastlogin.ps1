#-----------------------------------------
# check_P2V_admins
#
#  name:   check_P2V_user.ps1 
#  ver:    1.0
#  author: M.Kufner
#
# retrieve AD-settings for specific x-key
# arguments:
# $xkey =  xkey to search
# $long =  false (default)   - short summary 
# $long =  true              - all AD entries
# $P2Vgroups = true (default)/false   - show P2V AD group memberships
#-----------------------------------------
param(
  [string]$xkey="<no user>",
  [bool]$analyzeOnly = $True
)
#-------------------------------------------------
$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir\P2V_include.ps1"

#----- Set config variables
$output_path = $output_path_base + "\$My_name"

#-------------------------------------------------
P2V_header -app $My_name -path $My_path 
createdir_ifnotexists($output_path)
#----- start main part

#While ($result= P2V_get_AD_user_UI($xkey))
#{
#----- check whether xkey is member of workgroups in P2V
    $user =  $result.Name
	$UPN  =  $result.UserPrincipalName
    $dname=  "$($result.Surname) $($result.GivenName)"
	$linesep
    $form1 -f "checking P2V Planningspace user profile for"
    $form1 -f $result.displayName
	$linesep

    # $all_systems = @()
   
    #$tenants= P2V_get_tenant_UI($tenantfile)
	$tenants= select_PS_tenants  #-multiple $false
		
    foreach ($i in $tenants.keys)
    {
	  $t_sel=$tenants[$i]
      $form1 -f "-----> $($t_sel.tenant) <-----"
      	   
	  $authURL    ="$($t_sel.ServerURL)/identity/connect/token"
      $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t_sel.name, $t_sel.API)))
      $tenantURL  ="$($t_sel.ServerURL)/$($t_sel.tenant)"
  
    # retrieve all users incl. workgroups
      $resp=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
      if (!$resp) {$form2_1 -f "[ERROR]", "cannot contact $t_sel !" ;break}
      
	  #$resp=$resp |where {($($_.logOnId) -like $user) -or ($($_.logOnId) -like $UPN )}
	  
	  #$u_list_P2V = P2V_get_userlist ($t_sel)| where-Object {($($_.authenticationMethod) -ne 'LOCAL' -and $_.logOnId -eq $UPN) }
      #$u_list_P2V|% {$u1_list_P2V[$($_.logOnId)]=$_}
	  
	  $resp| select id,
				displayName,
				logOnId,
				isDeactivated,
				isAccountLocked,
				description,
	    		lastLogin |out-gridview  -Title "last Logins in tenant >> $($t_sel.tenant) <<" -PassThru |format-table
     
     }

P2V_footer -app $My_name
Read-Host "Press Enter to close the window"
# ----- end of file -----
