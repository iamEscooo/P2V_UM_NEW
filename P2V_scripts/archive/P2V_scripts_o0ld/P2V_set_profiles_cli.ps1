param(
  [bool]$debug = $True,
  [bool]$checkonly = $False
)
#-------------------------------------------------
$My_name=$($MyInvocation.MyCommand.Name)
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
$workdir=$My_Path
. "$workdir/P2V_include.ps1"

#----- Set config variables

$output_path = $workdir + "\output\$My_name"

#-------------------------------------------------
#P2V_layout 
cls
P2V_header -app $My_name -path $My_path 


#-- 1#   read profiles (profiles <> workgroups)
$P2V_profile=@{}    

$csv_profiles=import-csv -path $profile_file |sort profile
$valid_profiles= @()
$l1=""
$g_list=@()

foreach ($l in ($csv_profiles|sort profile)) 
{
  if ($($l.profile) -eq $l1) {$g_list+=$l.groups}
  else
  {
    If ($l1) 	
	{
	  $P2V_profile[$l1]=$g_list
	  $valid_profiles +=$l1
	  $g_list=@()
	}
	$g_list+=$l.groups
    $l1=$l.profile 
  }
}
if ($l1) {$P2V_profile[$l1]=$g_list;  $valid_profiles +=$l1}
$form_status -f "load profiles $profile_file","[DONE]"
$linesep

#$P2V_profile|format-list

#-- load Todo-list ( user <> profiles)
$P2V_user_profile=@{}
$P2V_user_workgroup=@{}
$todo_file=Get-FileName($workdir)

$todo_profiles=import-csv -path $todo_file

#if ($debug) {$todo_profiles|sort -property name|format-table}

$l1=""
$p_list=@()   # profile_list
$g_list=@()   # group_list
$todo_tenants =@()
foreach ($p in ($todo_profiles|sort logonID))  # sort users 
{
  #if ($valid_profiles -contains $($u.profile))  # does profile exist ?
  #{
  
      if ($($p.logonID) -eq $l1) 
	  { # same user in list or change?)
	    $p_list+=$p.profile;
		$P2V_profile[$p.profile]|% {if (!($g_list -contains $_)){$g_list+= $_}}
		if ($debug){write-host -nonewline " / $($p.profile)"}
	  } 
      else
      {
        If ($l1) 	
	    {
	      $P2V_user_profile[$l1]=$p_list
		  $P2V_user_workgroup[$l1]=$g_list
		  $p_list=@()
		  $g_list=@()
	    }
	    $p_list+=$p.profile
		$P2V_profile[$p.profile]|% {if (!($g_list -contains $_)){$g_list+= $_}}
		$l1=$p.logonID 
		if ($debug) {write-host -nonewline "`n$l1 -> $($p.profile)"}
      }
	  
	  if (!($todo_tenants -contains $($p.tenant))) {$todo_tenants+=$p.tenant}
  #}
  #else
  #{write-log ("$($u.profile) not a valid profile", 2)
  #$form_status -f "$($u.profile) not a valid profile", "[ERROR]"}
}
if ($debug){Write-host}
if($($p_list.count) -gt 0){ $P2V_user_profile[$l1]=$p_list   }
if($($g_list.count) -gt 0){ $P2V_user_workgroup[$l1]=$g_list }
#--  controls output
if ($debug)
{
  $form1 -f "[$($P2V_profile.count)] Profiles <> workgroups"
   $P2V_profile.getenumerator()|sort -property name|format-table;
  $form1 -f "[$($P2V_user_profile.count)] users <> profiles"
   $P2V_user_profile.getenumerator() |sort -property name|format-table
  $form1 -f "[$($P2V_user_workgroup.count)] Users <> workgroups"
   foreach($k in $p2V_user_workgroup.keys)
   { 
     $form1 -f $k
	 $p2V_user_workgroup[$k]|% {$form2 -f "",$_}
   }
   
  $form1 -f "[$($todo_tenants.count)] tenant(s) found in profile-file:"
   $todo_tenants
}
#-- translate user/profile in user/workgroup


#-- 2 select tenant
If (!$tenant) {$t_sel= P2V_get_tenant($tenantfile)}
$tenant=$t_sel.tenant
$tenantURL  ="$($t_sel.ServerURL)/$($t_sel.tenant)"
$authURL    ="$($t_sel.ServerURL)/identity/connect/token"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t_sel.name, $t_sel.API)))

$overwrite=((Read-host ($form1 -f "overwrite (o) or append (a = default) to current group assignments in [$tenant]")) -eq "o")

$all_P2V_users=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users?include=UserWorkgroups" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
if (!$all_P2V_users) {$form_err -f "[ERROR]", "cannot contact $tenant !" ;exit}

# -- if overwrite -> create delete list

$linesep
foreach ($k in $P2V_user_profile.keys)
{
  $del_ops =@()
  $delete_ops= @{}
  $l_list= $P2V_user_profile[$k]
  if ($overwrite)  {    $form1 -f "delete: $k groups assignments" }
     $uid=$all_P2V_users|where {($($_.logonID) -eq $k)}
	 $uid
	 pause
     foreach( $g in $uid.userworkgroups)
     {
        $hash = @{}
        $g | Get-Member -MemberType Properties | select -exp "Name" | % { $hash[$_] = ($g | SELECT -exp $_) }
        foreach($wg in ($hash.Values | Sort-Object -Property id)) 
        {
	       if ($($wg.id) -ne "2")  # skip Everyone group 2
		   { 
			  $del_ops = [PSCustomObject]@{
                    op = "remove"
                    path = "/users/$($uid.id)"
                    value = ""							
		      }
			  $form_status -f " [$($uid.displayName)] group $($wg.id) / $($wg.name)","[REMOVE]"
			  			  $delete_ops["$($wg.id)"] =@($del_ops)
		   }
		}
	 }


}  
  
  foreach($j in $l_list)
  { 
    if ($debug){$form1 -f "  add: $k to $j  " }
  }


pause 
exit


$updateOperations = @{}
$user_ops = @{}
if ($overwrite)
{
  $linesep
  foreach ($uid in $u_sel)
  {
	 $del_ops =@()
     $delete_ops= @{}
	 
	 # missing part:  remove list of existing group assignments
	  
     foreach( $g in $uid.userworkgroups)
     {
        $hash = @{}
        $g | Get-Member -MemberType Properties | select -exp "Name" | % { $hash[$_] = ($g | SELECT -exp $_) }
        foreach($wg in ($hash.Values | Sort-Object -Property id)) 
        {
	       if ($($wg.id) -ne "2")  # skip Everyone group 2
		   { 
			  $del_ops = [PSCustomObject]@{
                    op = "remove"
                    path = "/users/$($uid.id)"
                    value = ""							
		      }
			  $form_status -f " [$($uid.displayName)] group $($wg.id) / $($wg.name)","[REMOVE]"
			  			  $delete_ops["$($wg.id)"] =@($del_ops)
		   }
		}
	 }
	 	
	 $user_ops["$($uid.id)"]=$delete_ops
	
    }   
}
 



pause
exit



#-- continue?
$linesep
$form1 -f "Please check changes before continuing.."

$form1 -f " in tenant $tenant the following users"
$linesep
$u_sel|select id,displayname,description|% {$form_user -f $_.id,$_.displayname,$_.description }
$linesep
$form1 -f " will be added to the profiles:"

$linesep

foreach ($p in  $profile_sel) {
 $form1 -f $p.key
 $p.value|%{$form2 -f "","$_"}
  
}
$linesep
$overwrite=((Read-host ($form1 -f "overwrite (o) or append (a = default) to current group assignment")) -eq "o")





if ($debug)
{
$user_ops|convertto-Json|out-host
$linesep
foreach ($k in $user_ops.keys){$user_ops[$k]|convertto-Json|out-host;"--"}
}
	 
$linesep

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
$linesep
$body = $updateOperations |convertto-Json
if (($cont=read-host ($form1 -f "apply changes? (y/n)")) -like "y")
{
   $linesep 
   foreach ($k in $user_ops.keys)
   {
   
	 if ($user_ops[$k].count -gt 0 )
	 {
	     $body = $user_ops[$k]|convertto-Json
		 if ($debug) { $body }
	     $apiUrl = "$($tenantUrl)/planningspace/api/v1/workgroups/bulk"
	     
         $i_result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ( $body ) -ContentType "application/json"
	 		 
		 $form_status -f  "removing current user  from $($user_ops[$k].count) workgroup assignments", "[DONE]"
		 
		 $i_result |format-list|out-host
			 
	  }
    }
	if ($debug)
	{
       "check now groups"
       pause
	}
 
    $body = $updateOperations |convertto-Json
 
    $linesep
    if ($updateOperations.Count -gt 0 )
	{
	    
		$apiUrl = "$($tenantUrl)/planningspace/api/v1/workgroups/bulk"	
        
		$i_result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ( $body ) -ContentType "application/json"
	 
	    $form_status -f  "changing $($updateOperations.Count) user /workgroups assignments", "[DONE]"
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
	 

P2V_footer -app $My_name 

