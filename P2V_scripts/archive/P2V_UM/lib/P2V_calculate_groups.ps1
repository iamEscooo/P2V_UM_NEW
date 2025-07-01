#=======================
#  calculate inverse group
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
  [bool]$checkonly = $FALSE,
  #[bool]$checkonly = $true,
  [bool]$debug = $false
)
#-------------------------------------------------
$My_name=$($MyInvocation.MyCommand.Name)
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir/P2V_include.ps1"
$user=$env:UserDomain+"/"+$env:UserName 

#----- Set config variables
$output_path = $output_path_base + "\$My_name"

$all_WG      = @{}
$tag_conf=$config_path +"\TAG_config.csv"
# TAG:  template access groups


P2V_header -app $My_name -path $My_path 

#-- 1  check tenant /select tenant
if(!$tenant) {$t= P2V_get_tenant($tenantfile)}
$tenant=$t.tenant

$authURL    ="$($t.ServerURL)/identity/connect/token"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t.name, $t.API)))
$tenantURL  ="$($t.ServerURL)/$($t.tenant)"


#-- 1.1  checkonly ?
if (($cont=read-host ($form1 -f "apply changes to $tenant ? (y/n =default)")) -like "y")
{ $checkonly=$FALSE} else { $checkonly=$true}
#-- 2  get all triple (allow,readonly,deny) groups
$tag=@()
Import-Csv $tag_conf | %{ $tag+=[PSCustomObject]@{
     allow    = "$($_.allow)"
     readonly = "$($_.readonly)"
     deny     = "$($_.deny)"
}}
$linesep
if ($debug) {$tag|format-table}

#-- 3  check whether groups exist
#-- 3.1 get all workgroups
$linesep
$all_workgroups=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/workgroups?include=users" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
if ($all_workgroups) { $gcount=$all_workgroups.count;$form_user1 -f  $gcount,"workgroups retrieved from $tenant","[DONE]"}
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
$total_count=0
foreach ($check_g in $tag)
{
   #-- 4 check wether groups exists
   foreach ( $cg in ($check_g.allow,$check_g.readonly,$check_g.deny))
   {
      if ($all_workgroups|where { ($cg -like $($_.name)) }) 
      {
        $all_workgroups|where { ($cg -like $($_.name))}|select id, name, users |%{$all_WG["$($_.id)"] = $_}
        # $form_status -f "$cg","[found]"
      } 
	  else  
	  { $form_status -f "$cg does not exist in $tenant","[ERROR]"; exit }
   }

   $linesep
   $form1 -f "[$($check_g.allow)] [$($check_g.readonly)] [$($check_g.deny)]"
   if ($debug) {$form_err -f "DEBUG",'$all_WG';$all_WG|format-table}    
   
   #-- 4.1 create userlists per group
   $allow_l=@{}
   $readonly_l=@{}
   $deny_l=@{}
   $allow_gid    = 0
   $readonly_gid = 0
   $deny_gid     = 0
   
   if ($debug) {$linesep|out-host}
   
   foreach ($wg in $all_WG.Values|sort-object -Property id)
   {
      #$form2 -f "checking",$wg.name |out-host
	  switch ($wg.name) 
	  {
	    "Administrators" {
		         $allow_gid=$wg.id
				 foreach($tmpUsers in $wg.users)
                   { 
	                   $tmpUsers | Get-Member -MemberType Properties | select -exp "Name" | % { $allow_l[$_] =($tmpUsers | SELECT -exp $_) }
    	               if ($debug) {$form_user1 -f $($allow_l.count),"users in >Administrators<","[ALLOW]"}
					    foreach($userId in $allow_l.Keys)
                         {
			                   $form_user -f $allow_l[$userid].id,$allow_l[$userid].name,"<1"|out-host
	 				     }
				   }		   
		} 
	    $check_g.allow {
		         $allow_gid=$wg.id
				 foreach($tmpUsers in $wg.users)
                   { 
	                   $tmpUsers | Get-Member -MemberType Properties | select -exp "Name" | % { $allow_l[$_] =($tmpUsers | SELECT -exp $_) }
    	               if ($debug) {$form_user1 -f $($allow_l.count),"users in $($check_g.allow)","[ALLOW]"}
					   # foreach($userId in $allow_l.Keys)
                        # {
			                  # $form_user -f $allow_l[$userid].id,$allow_l[$userid].name,"<1"|out-host
	 				    # }
				   }		   
		}
    
		$check_g.readonly {
		         $readonly_gid=$wg.id
		         foreach($tmpUsers in $wg.users)
                   { 
	                   $tmpUsers | Get-Member -MemberType Properties | select -exp "Name" | % { $readonly_l[$_] = ($tmpUsers | SELECT -exp $_) }
    	               if ($debug) {$form_user1 -f $($readonly_l.count),"users in $($check_g.readonly)","[READONLY]"}
					   # foreach($userId in $readonly_l.Keys)
                         # {
			            #      $form_user -f $readonly_l[$userid].id,$readonly_l[$userid].name,"<2"|out-host
	 				     # }
				   }
		}
	    
		$check_g.deny   {
		         $deny_gid =$wg.id
	             foreach($tmpUsers in $wg.users)
                    { 
	                   $tmpUsers | Get-Member -MemberType Properties | select -exp "Name" | % { $deny_l[$_] = ($tmpUsers | SELECT -exp $_) }
    	               if ($debug) {$form_user1 -f  $($deny_l.count), "users in $($check_g.deny)","[DENY]"}
		               # foreach($userId in $deny_l.Keys)
                        # {
			           #       $form_user -f $deny_l[$userid].id,$deny_l[$userid].name,"<3"|out-host
	 				    # }
				    }
		}
	  } # end switch
    }#end foreach
    
  $linesep
  out-host
  
  
  #-- 4.2 create change_ops list

  $c_count =0;
   
  #  binary setup (state0  asist  ; state 1 tobe)
	#                           bit    421
	#                                  x       ALLOW 1/0
	#                                   x     READONLY   1/0
	#                                    x   DENY 1/0
  $allow_code=    [convert]::toint32("0100",2)	 
  $readonly_code= [convert]::toint32("0010",2)	 
  $deny_code=     [convert]::toint32("0001",2)	 
 
  foreach ($u in $all_users)
  {
    $chg_ops =@()
    $change_ops= @{}
    $state0=0   # as-is setup  
	$state1=1   # to-be setup
		
	# calculate to-be status -  order matters !  implicit priority ...
	if ($state0 -eq 0)                         {$state1 = 1; $state2= "DENY"}
	if ($deny_l.containskey("$($u.id)"))       {$state0 = $state0 -bor $deny_code;$state1 = $deny_code; $state2= "DENY"}
	if ($readonly_l.containskey("$($u.id)"))   {$state0 = $state0 -bor $readonly_code;$state1 = $readonly_code; $state2= "R/O"}
	if ($allow_l.containskey("$($u.id)"))      {$state0 = $state0 -bor $allow_code;$state1 =  $allow_code; $state2= "FULL"}
	
	# change needed?
	if ($state0 -ne $state1)
	{
	  $c_count++
	  $total_count++
	  $change0=$state0 -bxor $state1   # which group to change
	  $c0=[convert]::tostring($change0,2).PadLeft(4, '0') 
	  $s0=[convert]::tostring($state0,2).PadLeft(4, '0')
	  $s1=[convert]::tostring($state1,2).PadLeft(4, '0')
			  
	  if ($state0 -band $change0)  
	  { # remove
	    $activity="remove"
	  } else 
	  { # add
	    $activity="add"
	  }
	  
	  	  
	  # not possible option ...
	  if ($change0 -band $allowcode) 
	  {  		 
         $chg_ops =  [PSCustomObject]@{
	          op    = "$activity"
              path  = "/users/$($u.id)"
              value = ""	
	      }
		 $change_ops["$allow_gid"] =@($chg_ops)
	  }
	  # more realistic ...
	  if ($change0 -band $readonly_code)
	  {  		 
         $chg_ops =  [PSCustomObject]@{
	          op    = "$activity"
              path  = "/users/$($u.id)"
              value = ""	
	      }
		 $change_ops["$readonly_gid"] =@($chg_ops)
	  } 
	 
	  # very often ...
	  if ($change0 -band $deny_code)
	  { 
	    $chg_ops =  [PSCustomObject]@{
	          op    = "$activity"
              path  = "/users/$($u.id)"
              value = ""	
	      }
		$change_ops["$deny_gid"] =@($chg_ops)
	  	 
	  }
	  
	  if ($change_ops.Count -gt 0 )
	  {
	     $body=  ($change_ops|convertto-json)
	     if ($checkonly)
		 {
		   
		   if ($debug)
		   {
		     $form_status -f "[$s0]>[$s1]=[$c0]$activity :$($u.displayname) ","[$state2]"  
		   }
		   $change_ops.keys|%{
	        $line="$($all_WG["$_"].name):  $activity  $($u.displayname)"
		    $form_status -f  $line, "[NOP]"
					 }
		 }
	     else
	     {
	        $apiUrl = "$($tenantUrl)/planningspace/api/v1/workgroups/bulk"	
            $i_result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ( $body ) -ContentType "application/json"
			$change_ops.key|%{$all_WG["$_"].name;
	        $line=$($all_WG["$_"].name)+":  $activity  $($u.displayname)"
		    If ($i_result["$_"]) 
	         {$form_status -f  $line, "[DONE]"} else
			 {$form_status -f  $line, "[ERROR]"} 
			 #$i_result["$_"]|format-table
			 	 
			 }
		 } 
      }
	}
	
 } # end foreach users
 $linesep
 $form1 -f "$c_count update operations"
 }
$linesep
$form1 -f "$total_count update operations in total"
P2v_footer -app $My_name    
exit
