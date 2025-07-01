#P2V_set_profiles
<#  documentation
.SYNOPSIS
	short  BLABLA
.DESCRIPTION
	long BLABLA

.PARAMETER  arguments <xxx>  
	describe 1 .. n arguments
	
.PARAMETER  arguments <xxx>  
	describe 1 .. n arguments
	

.INPUTS
	none

.OUTPUTS
	true / false

.EXAMPLE
	Example of how to run the script.

.LINK
	Links to further documentation.

.NOTES
  
#>
param(
  [bool]$debug = $false,
  [bool]$checkonly = $False
)
#-------------------------------------------------

$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir/P2V_include.ps1"

#----- Set config variables
$output_path = $output_path_base + "\$My_name"
$Prof_logfile= $output_path + "\profiles.log"

#-------------------------------------------------
P2V_header -app $My_name -path $My_path 
createdir_ifnotexists($output_path)

#-------------------------------------------------
#P2V_layout 

$P2V_profile=@{}
$add_log =@()
$delete_log =@()

#-- 1#   read profiles
$form1 -f "loading profiles from $profile_file"
$csv_profiles=import-csv -path $profile_file |sort profile
$l1=""
$g_list=@()

foreach ($l in $csv_profiles) 
{
     $P2V_profile["$($l.profile)"]+= @($($l.groups))
}

$form_status -f "load profile definitions $profile_file","[DONE]"
$linesep
if ($debug) {$P2V_profile|format-table |out-host }

$csv_profiles|convertto-Json|out-file "$output_path\csvprofiles.json"

#-- 2# select tenant

$tenants= select_PS_tenants -multiple $false

foreach ($ts in $tenants.keys)
{
   $t=$tenants[$ts]
   $tenant=$t.tenant
   $PS_user_1=  @{}
   $u_sel	  = @{}
   $tenantURL  ="$($t.ServerURL)/$($t.tenant)"
   $base64AuthInfo = "$($t.base64AuthInfo)"
   $profiles_U= $output_path + "\$($tenant)_profiles.log"
      
   #-- 3# select (multiple) user(s)
   $PS_users= get_PS_userlist -tenant $t
   if (!$PS_users) {exit}
   $PS_users|% {$PS_user_1[$($_.logOnId)]=$_}	 	 
   
   $u_s=$PS_users |select id,displayName,logOnId,description,authenticationMethod,emailAddress,isDeactivated,isAccountLocked|out-gridview -title "select user" -outputmode multiple
      
   #-- 4# select profile to apply
   # $P2V_profile|convertto-Json|out-file "$output_path\profiles.json"

   $profile_sel=$P2V_profile.GetEnumerator()|sort-object -Property Name |out-gridview -title "Select Profile to apply"  -outputmode multiple
    
   $csv_profiles|where { $($_.profile) -eq $($profile_sel.Value)}

 # $profile_sel.Value
 
#-- 5# extra treatment of local profiles
#-- 5.1  retrieve all workgroups
   #[OLD]$w_result=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/workgroups?include=users" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
   
   $w_result= get_PS_grouplist -tenant $t

   $updateOperations = @{}

   #-- continue?
   $linesep
   $form1 -f "Please check changes before continuing.."
   $form1 -f " in tenant $tenant the following changes are requested"
   $linesep
   $form2_2 -f "user" , "profile"
   $form2_2 -f "===========","==========="
   if (! (Test-Path $profiles_U)){ Add-Content -Path $profiles_U -Value 'logonId,profile'}
		
   foreach($u in $u_s)
   {
       $u_sel[$($u.logOnId)]=$PS_user_1[$($u.logonId)]
	   
       foreach ($p in  $profile_sel) 
	   {
	       $form2_2 -f "$($u.logonId)" , "$($p.key)"
           # $form1 -f $p.key
           # $p.value|%{$form2 -f "","$_"}  # print workgroupnames
		   Add-Content  $profiles_U -Value ( $($u.logonId) + "," + $($p.key) )
       }
   }
   $linesep
   out-host
   
   $u_s|select id,displayname,description|% {$form_user -f $_.id,$_.displayname,$_.description }
   $linesep
   $form1 -f " will be added to the profiles:"

#   $profile_sel|convertto-json|out-host
#   $linesep

   foreach ($p in  $profile_sel) {
     $form1 -f $p.key
     $p.value|%{$form2 -f "","$_"}  # print workgroupnames
    }
		
  $linesep
  $overwrite=((Read-host ($form1 -f "overwrite (o) or append (a = default) to current group assignment")) -eq "o")

  $updateOperations = @{}  # always remove /add  users from group   wg: + /- userid
  $delete_ops= @{}
  if ($overwrite)
  {
    $linesep
	
    foreach ($u in $($u_sel.keys))
    {
      $uid=$u_sel[$u]
	  $del_ops =@()
	 
	  # first loop to collect ""
	 	 
      foreach( $g in $uid.userworkgroups)
      {
        $hash = @{}
        $g | Get-Member -MemberType Properties | select -exp "Name" | % { $hash[$_] = ($g | SELECT -exp $_) }
        foreach($wg in ($hash.Values | Sort-Object -Property id)) 
        {
		   #----
		   if (!$updateOperations.ContainsKey("$($wg.id)"))
           {
              $updateOperations["$($wg.id)"] = @()
           }
		   if ($($wg.id) -ne "2")  # skip Everyone group 2
		   { 
		      $updateOperations["$($wg.id)"] += [PSCustomObject]@{
		        op = "remove"
                path = "/users/$($uid.id)"
                value = ""							
		      }
			  $form_status -f " [$($uid.displayName)] group $($wg.id) / $($wg.name)","[REMOVE]"
		  
              $delete_log += [PSCustomObject]@{						  
		         tenant			= $tenant
                 logOnId        = $uid.logonID
                 displayName 	= $uid.displayname
    		     workgroup      = $wg.name
			     activity       = "REMOVE"
		      }
		   }
		   
	    }
	    #$user_ops["$($uid.id)"]=$delete_ops
	  }   
	}
}    

if ($debug)
{
   $updateOperations|convertto-Json|out-host
   $linesep
   foreach ($k in $updateOperations.keys){$updateOperations[$k]|convertto-Json|out-host;"--"}
}
	 
$linesep

foreach ($wg in $w_result)
{
 if ($profile_sel.Value -contains $wg.Name)
  {
    $add_ops =@()
    foreach ($u in $($u_sel.keys))
     {
	    $uid=$u_sel[$u]
        #$form4 -f $wg.id,$wg.Name,$wg.description,$profile_sel.key
        $form_status -f " [$($uid.displayName)] group $($wg.id) / $($wg.name)","[ADD]"
     	$add_ops += [PSCustomObject]@{
                       op = "add"
                       path = "/users/$($uid.id)"
                       value = ""							
				    }
		$add_log += [PSCustomObject]@{						  
		        tenant			= $tenant
                logOnId         = $uid.logonID
                displayName 	= $uid.displayname
    		    workgroup       = $wg.name
			    activity        = "ADD"
			  }
	 }    
	 $updateOperations["$($wg.id)"]=$add_ops
	 
  }

}

$linesep
$body = $updateOperations |convertto-Json

if ($debug){$body|out-host}

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
		 #write_result ($i_result)
		 #"+-+"|out-host
		 #$i_result |format-list|out-host
		 write_result $i_result
			 
	  }
    }
	
	if ($debug)
	{
       "check now groups"
       pause
	}
 
    $body = $updateOperations |convertto-Json
    if ($($updateOperations.count) -eq 1 ){ $body="[ $body ]" }  
	
	#debug-print
    if ($debug){$body|out-host;pause}
		
   	$body = [System.Text.Encoding]::UTF8.GetBytes($body) 
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
			   #$i_result |format-list|out-host
			   write_result $i_result
			   $form1 -f " Finished updating workgroups" |out-host
			 }
	 }
	  else
     {
		  #ConvertTo-Json @($newUsers)|out-host
     }
	 
	 
	  
	 $form1 -f "removed assignments:"|out-host
	 $delete_log|format-table|out-host
	 $form1 -f "added assignments:"|out-host
	 $add_log|format-table|out-host

  
     Add-Content -Path $Prof_logfile -Value 'tenant,LogonId,DisplayName,workgroup,activity'	 
	 
     $delete_log |% {   Add-Content $Prof_logfile -Value ($($_.tenant) + "," + $($_.logOnId) + "," + $($_.displayName) + "," + $($_.workgroup) + "," + $($_.activity))}	 
	 $add_log    |% {   Add-Content $Prof_logfile -Value ($($_.tenant) + "," + $($_.logOnId) + "," + $($_.displayName) + "," + $($_.workgroup) + "," + $($_.activity))}	 

	 "check out $Prof_logfile"|out-host
	 }
	 
}
P2V_footer -app $My_name
Read-Host "Press Enter to close the window"
# ----- end of file -----
