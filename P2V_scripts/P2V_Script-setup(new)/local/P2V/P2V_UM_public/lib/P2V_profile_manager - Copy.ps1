#   P2V_profile_manager
#
#

#-------------------------------------------------
$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir/P2V_include.ps1"

$user=$env:UserDomain+"/"+$env:UserName  #+"@"+$env:ComputerName
#----- Set config variables

$output_path = $output_path_base + "\$My_name"
$profile_log= $output_path +"\P2V_user-profiles.csv"
$profile_file= $config_path + "\Xprofiles.json"

#-------------------------------------------------
#P2V_layout 
P2V_header -app $My_name -path $My_path 

createdir_ifnotexists $output_path


$P2V_profile=@{}

#-- 1#   read profiles
# $csv_profiles=import-csv -path $profile_file |sort profile
# $l1=""
# $g_list=@()
# foreach ($l in $csv_profiles) 
# {
  # if ($($l.profile) -eq $l1) {$g_list+=$l.groups}
  # else
  # {
    # If ($l1) 	
	# {
	  # $P2V_profile[$l1]=$g_list
	  # $g_list=@()
	# }
	# $g_list+=$l.groups
    # $l1=$l.profile 
  # }
# }

$P2V_profile=Get-Content -Raw -Path $profile_file| ConvertFrom-Json
$form_status -f "load profile definitions $profile_file","[DONE]"

$P2V_profile|out-gridview -title "[$tenant]:>> select profile(s)"  -outputmode multiple
$linesep
$P2V_profile.keys|%{ $form2 -f $_,$P2V_profile["$_"].value}
pause
exit
#-- 2# select tenant
If (!$tenant) {$t_sel= P2V_get_tenant($tenantfile)}
$tenant=$t_sel.tenant
$tenantURL  ="$($t_sel.ServerURL)/$($t_sel.tenant)"
$authURL    ="$($t_sel.ServerURL)/identity/connect/token"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t_sel.name, $t_sel.API)))
$output_path=$output_path + "\$tenant"
createdir_ifnotexists $output_path

#-- 3# select (multiple) user(s)

$resp=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users?include=UserWorkgroups" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
if (!$resp) {$form_err -f "[ERROR]", "cannot contact $tenant !" ;exit}

$u_sel=$resp |select id,displayName,logOnId,description,authenticationMethod,domain,accountExpirationDate,isDeactivated,isAccountLocked,authenticationType,emailAddress,useADEmailAddress,lastLogin,accountLockedDate,deactivatedDate,userWorkgroups |out-gridview -title "[$tenant]:>> select user(s) for profile-config" -outputmode multiple

#-- 4# select profile to apply
#P2V_Show-Menu -Title "Select P2V_profile" -menu $P2V_profile.keys

$P2V_profile.keys|%{ $form2 -f $_,$P2V_profile["$_"].value}

pause
exit
#$profile_sel=$P2V_profile|sort -property name|out-gridview -title "[$tenant]:>> select profile(s)"  -outputmode multiple
$profile_sel=$P2V_profile|select name| sort -property profile|out-gridview -title "[$tenant]:>> select profile(s)"  -outputmode multiple

#$csv_profiles|where { $($_.profile) -eq $($profile_sel.Value)}

#print part

$form1 -f " in tenant $tenant the following users"
$linesep
$u_sel|select id,logOnId,displayname,description|% {$form_user -f $_.id,$_.displayname,$_.description }
$linesep
$form1 -f " will be assigned to the profiles:"

$linesep

#--5# print result

 if (Test-Path $profile_log) 
 {
     if (($cont=read-host ($form1 -f "overwrite $($profile_log)? (y/n)")) -like "y") 
	 {
	   Delete-ExistingFile ($profile_log)
       Add-Content -Path $profile_log    -Value 'tenant,UID,logOnId,displayName,profile'	   
	 }
 }
 else 
 {Add-Content -Path $profile_log    -Value 'tenant,UID,logOnId,displayName,profile'}
 



foreach ($p in  $profile_sel) {
 $form1 -f $p.key |out-host
 
 #$p.value| 
 # %{ 
		#$form2 -f "","$_";
		$u_sel|%{$($_.id) |select id,displayname,logOnId |
		write-log "[$user]:$tenant,$($_.id),$($_.logOnId),$($_.displayname),$($p.key)"; 
		Add-Content -Path $profile_log  -Value "$tenant,$($_.id),$($_.logOnId),$($_.displayname),$($p.key)"}
 #  }
 }
 
 
P2V_footer -app $My_name
Read-Host "Press Enter to close the window"
# ----- end of file -----
