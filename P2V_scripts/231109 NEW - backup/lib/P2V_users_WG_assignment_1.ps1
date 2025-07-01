#=======================
# P2V_users_WG_assignment
#
#  name:   P2V_users_WG_assignment_1.ps1 
#  ver:    1.0
#  author: M.Kufner
#=======================

param(
  [string]$tenant="",
  [string]$xkey="",
  [bool]$debug = $False,
  [bool]$checkonly = $True
)

$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir/P2V_include.ps1"

#-------------------------------------------------
#  Set config variables

$output_path = $output_path_base + "\$My_name"
$u_w_file= $output_path + "\Myuserworkgroup.csv"

#-------------------------------------------------
#layout

P2V_header -app $My_name -path $My_path 

If (!$tenant) {$t_sel= P2V_get_tenant($tenantfile);$tenant=$t_sel.tenant}

# $u_sel= P2V_get_AD_user_UI($xkey)
# $user =  $u_sel.Name
# $UPN  =  $u_sel.UserPrincipalName
# $dname=  "$($u_sel.Surname) $($u_sel.GivenName)"


$authURL    ="$($t_sel.ServerURL)/identity/connect/token"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t_sel.name, $t_sel.API)))
$tenantURL  ="$($t_sel.ServerURL)/$($t_sel.tenant)"

$resp=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users?include=UserWorkgroups" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
if (!$resp) {$form_err -f "[ERROR]", "cannot contact $tenant !" ;exit}

$u_sel=$resp |select id,displayName,logOnId,description,authenticationMethod,domain,accountExpirationDate,isDeactivated,isAccountLocked,authenticationType,emailAddress,useADEmailAddress,lastLogin,accountLockedDate,deactivatedDate,userWorkgroups |out-gridview -title "select user" -outputmode single
#$resp=$resp |where {($($_.logOnId) -like $user) -or ($($_.logOnId) -like $UPN )}
$form1 -f ""
$uid=$u_sel.id
$dname=  $u_sel.Displayname
$form_user -f $uid,$dname,$u_sel.logonId


$linesep
$form2 -f "tenant:",$tenant
$form2 -f "login:",$u_sel.LogOnId
$form2 -f "user:",$u_sel.displayName
$linesep
#$user|format-table

# initialize lists
$current_WG  = @()
$delete_WG   = @()
$add_WG      = @()
$new_WG      = @()
$all_WG      = @{}
$usersLookup=@{}
$updateOperations = @{}


$linesep

$form1 -f "current workgroups:"
foreach( $g in $u_sel.userworkgroups)
{
   $hash = @{}
   $g | Get-Member -MemberType Properties | select -exp "Name" | % { $hash[$_] = ($g | SELECT -exp $_) }
   foreach($wg in ($hash.Values | Sort-Object -Property id)) 
   {
		$current_WG +=[PSCustomObject] @{
			id =    $wg.id
			name =  $wg.name
		}
   }   
}
$current_WG |%{ $form_user -f $($_.id), $($_.name),""}
$current_WG |%{ $usersLookup["$($_.id)"] = $_ }
#$linesep
#$userslookup
#$linesep

$w_result=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/workgroups?include=users" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}

if (!$w_result) {$form2_1 -f "[ERROR]", "cannot contact $i !" ;break}
$w_result |sort-object -property id |%{$all_WG[$($_.id)] = $_}
#[PSCustomObject] @{
#			id =    $_.id
#			name =  $_.name
#			description = $_.description
#			}}

#$all_WG=$all_WG.GetEnumerator() | Sort-Object -Property key
  
$linesep

do 
{
   $nwg=""
   
   While(!$nwg) {$nwg=read-host ($form1 -f "select group(s) to change  (a - add, d - delete, l - list;0 - continue)")}
   $linesep
   switch ($nwg) 
   {
       '0'  { # continue
	           			   break
	        } 
       {@('l','L') -contains $_ }
			{
			  $linesep
			  $form1 -f "all available workgroups:"
			  $linesep
			  $all_wG.values | out-gridview -title "all available workgroups"
              #$all_WG.values | Sort-Object -Property id|%{ $form_user -f $($_.id), $($_.name),$($_.description)}			
			  $linesep
	        }
      {@('d','D') -contains $_ }
	        {
			   $delete_WG   = $current_WG |out-gridview -title "<<-- select groups to delete for $dname -->>" -outputmode multiple
			   
			   #$delete_WG|format-table|out-host
			   
			   $delete_WG |% {
			      $wg_id=$($_.id)
				  $wg_name=$($_.name)
				  if ($wg_id -ne "2")
				  {
		    	    $form_status -f " [$dname] will be removed from group $wg_id / $($all_wg[$wg_id].name)","[REMOVE]"
			        $updateOperations["$wg_id"] = [PSCustomObject]@{
                       op = "remove"
                       path = "/users/$uid"
                       value = ""							
				    }
				  }
			   }
			  		   
			   
			}
	  {@('a','A') -contains $_ }     
	        {
			   $add_WG = $all_wG.values|out-gridview -title "<<-- select groups to add for $dname -->>" -outputmode multiple
			   
			   #$add_WG|select id,name|format-table|out-host
			   
			   $add_WG |% {
			      $wg_id=$($_.id)
				  $wg_name=$($_.name)
				  if ($userslookup.Keys -contains $wg_id)
				  {
				    $form_status -f " [$dname] already in group $wg_id / $($all_wg[$wg_id].name)","[KEEP]"
				  }
				  else
				  {
		    	    $form_status -f " [$dname] will be added to group $wg_id / $($all_wg[$wg_id].name)","[ADD]"
			        $updateOperations["$wg_id"] = [PSCustomObject]@{
                       op = "add"
                       path = "/users/$uid"
                       value = ""							
				    }
				  }
				  }
			   
			   
			}
      #'2'
	       # {
		     # $wg_id=[int]$nwg
		#	 $wg_id
		#	 $all_wg[$wg_id]
		    # if ($all_WG.Keys -contains $nwg) 
               # {
			     # if ($userslookup.Keys -contains $nwg)
				  # {
				    # $form1 -f " [$dname] will be removed from group $wg_id / $($all_wg[$wg_id].name)"
					# $updateOperations["$wg_id"] = [PSCustomObject]@{
                       # op = "remove"
                       # path = "/users/$uid"
                       # value = ""							
				     # }
				  # }
				  # else
				  # {
				    # $form1 -f " [$dname] will be added to group $wg_id / $($all_wg[$wg_id].name)"
			        				
		            # $new_WG += [PSCustomObject] @{
		        	  # id   =  $all_wg[$wg_id].id
                      # name =  $all_wg[$wg_id].name 
				    # }
				    # $updateOperations["$wg_id"] = [PSCustomObject]@{
                      # op = "add"
                      # path = "/users/$uid"
                      # value = ""							
				    # }
                  # }					
			    # }
			 # else
			    # {"group not found"}
		   #} 
   }
    
}until ($nwg -eq "0")

#$form1 -f "workgroups to add to user:"
#$new_WG #|%{ $form_user -f $($_.id), $($_.name)}

foreach ($k in $($updateOperations.keys))
 {
   $updateOperations[$k]=@($updateOperations[$k])
 }

$body= ConvertTo-Json $updateOperations
if ($debug) {$body}

if (($cont=read-host ($form1 -f "continue (y/n)")) -like "y")
     
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
	 
P2V_footer -app $My_name

