#=======================
#  create new user
#
#  name:   calculate_inverse_group.ps1 
#  ver:    1.0
#  author: M.Kufner
#=======================

param(
  [string]$allow="",
  [string]$readonly="",
  [string]$deny="",
  [string]$tenant="",
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
$u_w_file= $output_path + "\Myuserworkgroup.csv"


$all_WG      = @{}
$tag_conf=$config_path +"\TAG_config.csv"
# TAG:  template access groups

cls
P2V_header -app $My_name -path $My_path 

#-- 1  check tenant /select tenant
if(!$tenant) {$t= P2V_get_tenant($tenantfile)}
$tenant=$t.tenant

$authURL    ="$($t.ServerURL)/identity/connect/token"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t.name, $t.API)))
$tenantURL  ="$($t.ServerURL)/$($t.tenant)"

#-- 2  get all triple (allow,readonly,deny) groups
$tag=@()
Import-Csv $tag_conf | %{ $tag+=[PSCustomObject]@{
     allow    = "$($_.allow)"
     readonly = "$($_.readonly)"
     deny     = "$($_.deny)"
}}
$linesep
$tag|format-table


#-- 3  check wether groups exist
#-- 3.1 get all workgroups
$linesep
$w_result=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/workgroups?include=users" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
if ($w_result) { $gcount=$w_result.count;$form_user1 -f  $gcount,"workgroups retrieved from $tenant","[DONE]"}
    else       { $form_user1 -f  "NO", "workgroups retrieved from $tenant","[ERROR]" ;exit}

#-- 3.2 retrieve all users
$all_users=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users?include=UserWorkgroups" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"} 

if ($all_users) { $ucount=$all_users.count;$form_user1 -f  $ucount, "users retrieved from $tenant","[DONE]"}
    else       { $form_user1 -f  "NO", "users retrieved from $tenant","[ERROR]" ;exit}
 
   #$all_users = $all_users|where { ($_.id -ne "1") }
   $all_users = $all_users|where { ($_.authenticationMethod -ne "LOCAL") }
   $all_users = $all_users|where { ($_.IsDeactivated -ne $true) }
   
   $c=$all_users.count
   $form_user1 -f $c, "users identified", "[DONE]"


#-- foreach TAG -triple
foreach ($check_g in $tag)
{
   #-- 4 check wether groups exists
   foreach ( $cg in ($check_g.allow,$check_g.readonly,$check_g.deny))
   {
      if ($w_result|where { ($cg -like $($_.name)) }) 
      {
        $w_result|where { ($cg -like $($_.name))}|select id, name, users |%{$all_WG["$($_.id)"] = $_}
        # $form_status -f "$cg","[found]"
      } 
	  else  
	  { $form_status -f "$cg does not exist in $tenant","[ERROR]"; exit }
   }

   $linesep
   $form1 -f "[$($check_g.allow)] [$($check_g.readonly)] [$($check_g.deny)]"
      
   
   #-- 4.1 create userlists per group
   $allow_l=@{}
   $readonly_l=@{}
   $deny_l=@{}
   $linesep|out-host
   foreach ($wg in $all_WG.Values|sort-object -Property id)
   {
     #$form2 -f "checking",$wg.name |out-host
	 switch ($wg.name) 
	 {
	    $check_g.allow {
				 foreach($tmpUsers in $wg.users)
                   { 
	                   $tmpUsers | Get-Member -MemberType Properties | select -exp "Name" | % { $allow_l[$_] =($tmpUsers | SELECT -exp $_) }
    	               $form_user1 -f $($allow_l.count),"users in $($check_g.allow)","[ALLOW]"
					   foreach($userId in $allow_l.Keys)
                        {
		#	                  $form_user -f $allow_l[$userid].id,$allow_l[$userid].name,"<1"|out-host
	 				    }
				   }		   
		}
    
		$check_g.readonly {
		         foreach($tmpUsers in $wg.users)
                   { 
	                   $tmpUsers | Get-Member -MemberType Properties | select -exp "Name" | % { $readonly_l[$_] = ($tmpUsers | SELECT -exp $_) }
    	               $form_user1 -f $($readonly_l.count),"users in $($check_g.readonly)","[READONLY]"
					   foreach($userId in $readonly_l.Keys)
                         {
		#	                  $form_user -f $readonly_l[$userid].id,$readonly_l[$userid].name,"<2"|out-host
	 				     }
				   }
		}
	    
		$check_g.deny   {
		         $deny_wgid =$wg.id
	             foreach($tmpUsers in $wg.users)
                    { 
	                   $tmpUsers | Get-Member -MemberType Properties | select -exp "Name" | % { $deny_l[$_] = ($tmpUsers | SELECT -exp $_) }
    	               $form_user1 -f  $($deny_l.count), "users in $($check_g.deny)","[DENY]"
		               foreach($userId in $deny_l.Keys)
                        {
		#	                  $form_user -f $deny_l[$userid].id,$deny_l[$userid].name,"<3"|out-host
	 				    }
				    }
		}
	} # end switch
  }#end foreach
    
  $linesep
  out-host
  
  
  #-- 4.2 create DENY-tobe list
  $deny_tobe = @{}

  foreach ($u in $all_users)
  {
    # if user not in allow_l or readonly_l -->  add to deny_l
    if ($allow_l.containskey("$($u.id)") -or $readonly_l.containskey("$($u.id)")) 
    {
      #$form_status -f "[$($u.id)] $($u.displayname) is allowed","[SKIP]" 
    } 
    else
    {
      $deny_tobe[$u.id]=[PSCustomObject]@{
	       id = $u.id
		   name = $u.logOnId
		   link = "/users/$($u.id)"
	  }
    }
  }
  $c=$deny_tobe.count
  $form_user1 -f $c,"users added to deny-tobe list","[DONE]"

  #-- 6 create operations
  $linesep
  #$form1 -f "create-OPS"
  $updateOperations= @()
  $all_ops = @()
  $delete_ops = @()
  $add_ops    = @()

  #">> ["+$deny_l.count+"] deny-l  / ["+$deny_tobe.count+"] deny_tobe <<"

  foreach($uid in $deny_l.Keys)
  {
     if ($deny_tobe.keys -contains $uid)  {
       #$form_status -f "$uid / $($deny_l[$uid].name) from $($c_g.deny) ","[KEEP]"
     }
     else
     { 
	 
	   if ($all_users|where { ($_.id -eq  $uid)})
	   {
        $form_status -f "$uid / $($deny_l[$uid].name) from $($check_g.deny) ","[REMOVE]"
	    $delete_ops += [PSCustomObject]@{
              op    = "remove"
              path  = "/users/$uid"
              value = ""	
        }
       } else{$form_status -f "$uid / $($deny_l[$uid].name)  not in identified users","[SKIP]"}		
	   
     }	
   }
   $all_ops += @($delete_ops)

  foreach($uid in $deny_tobe.Keys)
  { 
    if ($deny_l.keys -contains $uid)
	{
	  #  $form_status -f "$uid / $($deny_tobe[$uid].name) already in $($c_g.deny) ","[SKIP]"
    }
	else
	{
	   $form_status -f "$uid / $($deny_tobe[$uid].name) not in $($check_g.deny) ","[ADD]"
	   $add_ops += [PSCustomObject]@{
              op    = "add"
              path  = "/users/$uid"
              value = ""	
       }  
	   
	} 
  }
  $all_ops += @($add_ops)

  #$add_ops["$deny_wgid"]=@($updateOperations)

  #-- 7  print result
  #$all_ops = @($delete_ops)
  #$all_ops += @($add_ops)

  $form_user1 -f $delete_ops.count, "REMOVE-ops",""
  $form_user1 -f $add_ops.count,"ADD-ops",""
  $form_user1 -f $all_ops.count,"total ops",""
  
  $linesep

  $body= ConvertTo-Json $all_ops
  #$body 

  #--8 confirm to proceed an apply changes
  if (($cont=read-host "apply changes (y/n)") -like "y")
  {
     $linesep
     if ($all_ops.Count -gt 0 )
	 {
	    $form1 -f "$tenantURL/PlanningSpace/api/v1/workgroups/$deny_wgid"
		$apiUrl = "$($tenantUrl)/planningspace/api/v1/workgroups/$deny_wgid"	
        $i_result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ( $body ) -ContentType "application/json"
	 
	    
        If (!$i_result) { $form_status -f  "executing ",$all_ops.count," changes", "[ERROR]"}
        else {
		       
               $form1 -f " Creation result:"
               $i_result #| Out-gridview -title "result of Workgroup changes" -wait
			   $form1 -f " Finished updating workgroups"
			 }
	 }
	  else
     {
	 
	#	  $body 
     }
  }
  else
  {
	$form1 -f "skipping changes"  
		  
#	$all_ops |format-table
  }
  
  $linesep
  pause
}
  #-- 9  check result
 

P2v_footer -app $My_name

