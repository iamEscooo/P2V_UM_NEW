#-----------------------------------------
# check_P2V_user 
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
$My_name=$($MyInvocation.MyCommand.Name)
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
$workdir=$My_Path
. "$workdir/P2V_include.ps1"

#----- Set config variables

$config_path = $workdir + "\config"
$adgroupfile = $config_path + "\all_adgroups.csv"
$tenantfile  = $config_path + "\all_tenants.csv"
$output_path = $workdir + "\output\$My_name"
$u_w_file= $output_path + "\Myuserworkgroup.csv"

#-------------------------------------------------
#layout
#P2V_layout 
cls
P2V_header -app $My_name -path $My_path 
createdir_ifnotexists($output_path)
#----- start main part

While ($result= P2V_get_AD_user_UI($xkey))
{
#----- check whether xkey is member of workgroups in P2V
    $user =  $result.Name
	$UPN  =  $result.UserPrincipalName
    $dname=  "$($result.Surname) $($result.GivenName)"
	$linesep
    $form1 -f "checking P2V Planningspace user profile for"
    $form3 -f $user, $UPN, $dname
	$linesep

    $all_systems = @()
    $all_systems =import-csv $tenantfile
	
	
    foreach ($i in $all_systems)
    {
      $form1 -f "--> $($i.tenant) <--"
      	   
	  $authURL    ="$($i.ServerURL)/identity/connect/token"
      $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $i.name, $i.API)))
      $tenantURL  ="$($i.ServerURL)/$($i.tenant)"
         
                 
    # retrieve all users incl. workgroups
      $resp=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users?include=UserWorkgroups" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
      if (!$resp) {$form2_1 -f "[ERROR]", "cannot contact $i !" ;break}
      $resp=$resp |where {($($_.logOnId) -like $user) -or ($($_.logOnId) -like $UPN )}
      
      if ($resp) 
      {
         #$resp |select id, displayName, logOnId,  authenticationMethod,isDeactivated, isAccountLocked, lastlogon | format-list #          | write-verbose $form2 
         $resp |% {$i=$_; "id", "displayName", "logOnId",  "authenticationMethod","isDeactivated", "isAccountLocked", "lastLogin" |%{$form2_1 -f "  $_ :","$($i.$_)"}}
          
		  
         $form1 -f "  workgroups: "
         foreach( $g in $resp.userworkgroups)#{ $g|format-list| out-host   }
         {
            
            $hash = @{}
            
            $g | Get-Member -MemberType Properties | select -exp "Name" | % { $hash[$_] = ($g | SELECT -exp $_) }
            foreach($wg in ($hash.Values | Sort-Object -Property Name)) {$form2 -f $($wg.id), $($wg.name) }   
         }
         out-host
       } else 
       {
          $form2_1 -f "[ERROR]", "$user does not exist"
       }
       $linesep
     }
} 
  #write-host  -ForegroundColor yellow $linesep
 # end while

