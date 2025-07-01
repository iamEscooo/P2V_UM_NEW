param(
  [bool]$debug = $False,
  [bool]$checkonly = $True
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
$profile_file= $config_path +"\P2V_profiles.csv"

#-------------------------------------------------
#P2V_layout 
cls
P2V_header -app $My_name -path $My_path 

$P2V_profile=@{}

#-- 1#   read profiles
$csv_profiles=import-csv -path $profile_file |sort profile
$l1=""
$g_list=@()
foreach ($l in $csv_profiles) 
{
  if ($($l.profile) -eq $l1) {$g_list+=$l.groups}
  else
  {
    If ($l1) 	
	{
	  $P2V_profile[$l1]=$g_list
	  $g_list=@()
	}
	$g_list+=$l.groups
    $l1=$l.profile 
  }
}
$form_status -f "load profile definitions $profile_file","[DONE]"
$linesep

$P2V_profile|format-list
$linesep
#-- 2# select tenant
If (!$tenant) {$t_sel= P2V_get_tenant($tenantfile)}
$tenant=$t_sel.tenant
$tenantURL  ="$($t_sel.ServerURL)/$($t_sel.tenant)"
$authURL    ="$($t_sel.ServerURL)/identity/connect/token"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t_sel.name, $t_sel.API)))

#-- 3# select (multiple) user(s)

$resp=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users?include=UserWorkgroups" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
if (!$resp) {$form_err -f "[ERROR]", "cannot contact $tenant !" ;exit}

$u_sel=$resp |select id,displayName,logOnId,description,authenticationMethod,domain,accountExpirationDate,isDeactivated,isAccountLocked,authenticationType,emailAddress,useADEmailAddress,lastLogin,accountLockedDate,deactivatedDate,userWorkgroups |out-gridview -title "select user" -outputmode multiple

$u_sel|select id,displayname,description |format-table

#$P2V_profile|convertto-Json #> profiles.json

#-- 4# select profile to apply
#P2V_Show-Menu -Title "Select P2V_profile" -menu $P2V_profile.keys

$profile_sel=$P2V_profile|out-gridview -title "Select Profile to apply"  -outputmode single
$csv_profiles|where { $($_.profile) -eq $($profile_sel.Value)}
 # $profile_sel.Value
#-- 5# extra treatment of local profiles
#-- 5.1  retrieve all workgroups
$w_result=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/workgroups?include=users" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}


$updateOperations = @{}

#-- continue?
$linesep
$form1 -f "Please check changes before continuing.."

$form1 -f " in tenant $tenant the following users"
$linesep
$u_sel|select id,displayname,description|% {$form_user -f $_.id,$_.displayname,$_.description }
$linesep
$form1 -f " will be added to the profile: $($profile_sel.key)"
$form1 -f " and therefore to the groups:"
$linesep
$profile_sel.Value |% {$form1 -f $_}
$linesep
$overwrite=((Read-host "overwrite current group assignment (o) or append (a = default)") -eq "o")
$linesep
if ($overwrite)
{
  $form1 -f "start removing user from existing workgroups"
    
  foreach ($uid in $u_sel)
     {
	  
	  # missing part:  remove list of existing group assignments

     }
	 
	 
	 
$linesep
}


foreach ($wg in $w_result)
{
 if ($profile_sel.Value -contains $wg.Name)
  {
    $add_ops =@()
    foreach ($uid in $u_sel)
     {
        #$form4 -f $wg.id,$wg.Name,$wg.description,$profile_sel.key
        $form_status -f " [$($uid.displayName)] group $($wg.id) / $($wg.name)","[ADD]"
     	$add_ops += [PSCustomObject]@{
                       op = "add"
                       path = "/users/$($uid.id)"
                       value = ""							
				    }
	 }    
	 $updateOperations["$($wg.id)"]=$add_ops
	 
  }

}

if ($debug){$updateOperations |convertto-Json}

$body = $updateOperations |convertto-Json
if (($cont=read-host ($form1 -f "apply changes? (y/n)")) -like "y")
     
 {
	 $linesep
     if ($updateOperations.Count -gt 0 )
	 {
	    #$form1 -f "$tenantURL/PlanningSpace/api/v1/workgroups/bulk"
		$apiUrl = "$($tenantUrl)/planningspace/api/v1/workgroups/bulk"	
        $i_result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ( $body ) -ContentType "application/json"
	 
	    $form_status -f  "changing  user /workgroups assignments", "[DONE]"
        If (!$i_result) { $form_err -f "ERROR", "insert failed"}
        else {
               $form1 -f " Creation result:"
               #$i_result #| format-table|out-host #|Out-gridview -title "result of Workgroup changes" -wait
			   $i_result |format-list|out-host 
			   $form1 -f " Finished updating workgroups" |out-host
			 }
	 }
	  else
     {
		  #ConvertTo-Json @($newUsers)|out-host
     }
}
	 


pause

exit

$csv_profiles|where {}
$p_type=$P2V_profile[$($profile_sel.Value)]
if ($($profile_sel.type) -like "LOCAL" )
{
  $country=read_host "enter country"
  }

