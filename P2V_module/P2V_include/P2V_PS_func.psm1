#=================================================================
#  P2V_PS_func.psm1
#=================================================================
if (get-module -name "P2V_config") {if ($debug) {(Get-Module -name "*P2V*")|out-gridview -title "modules - loaded" -wait}}
else                               { import-module -name "..\P2V_config.psd1" -verbose }
if (get-module -name "P2V_AD_func") {if ($debug) {(Get-Module -name "*P2V*")|out-gridview -title "modules - loaded" -wait}}
else                               { import-module -name "..\P2V_AD_func.psd1" -verbose }
<#
.SYNOPSIS
	different dialog forms for P2V Usermgmt
.DESCRIPTION
	

.PARAMETER menufile <filename>
	
	
.PARAMETER xamldir <directory>
	
	
.PARAMETER fcolor  <colorcode>
	foregroundcolor of menubuttons  
    colorcode = colorname like 'lightblue'  or HEXcode like #003366"

.PARAMETER bcolor  <colorcode>
	backgroundcolor of menubuttons  
    colorcode = colorname like 'lightblue'  or HEXcode like #003366"

.INPUTS
	Description of objects that can be piped to the script.

.OUTPUTS
	Description of objects that are output by the script.

.EXAMPLE
	Example of how to run the script.

.LINK
	Links to further documentation.

.NOTES
  name:   P2V_PS_func.psm1
  ver:    1.0
  author: M.Kufner

#>

#=================================================================
# Variables
#=================================================================
$global:P2V_userlist=@{}
# structure:
# $P2V_userlist[$tenant]=@{
#                          createdate = $date;
#                          list       = @{Userlist from API}
#                         }


#=================================================================
# Functions
#=================================================================
#-----------------------------------------------------------------
Function select_PS_tenants 
{ # funtion to select tenant via GUI  -> returns list (1..n  tenants)
  # returns array  $selected_tenants[tenantname]=@{
  #        system         = from Csv $tenantfile
  #        ServerURL      = from Csv $tenantfile
  #        tenant         = from Csv $tenantfile
  #        resource       = from Csv $tenantfile
  #        name           = from Csv $tenantfile
  #        API            = from Csv $tenantfile
  #        ADgroup        = from Csv $tenantfile
  #        base64AuthInfo : calculated string  
  #}
  param (
         [bool] $multiple=$true, 
	     [bool] $all=$false
	 )

  $t_sel= @{}
  $t_list= @{}
  $t_resp= @{}
  
  $all_tenants =import-csv $tenantfile 
  $all_tenants |% {$t_list[$($_.tenant)]=$_}
  if (!$all_tenants) {$form_err -f "[ERROR]"," tenantfile $tenantfile does not exist"; exit }
     
  
  if ($all)      
  {  $t_sel=$all_tenants  }
  else
  {  
    if ($multiple) {$out_mode="multiple"}else {$out_mode="single"}
    $t_sel=$all_tenants|select system,tenant, ServerURL |out-gridview -Title "select tenant(s)" -outputmode $out_mode
  }

#  add baseauthstring to tenant
  $t_sel|%{ $t_resp[$_.tenant]=$t_list[$_.tenant];`
            $b=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t_list[$_.tenant].name, $t_list[$_.tenant].API)));`
		    $t_resp[$_.tenant]| Add-Member -Name 'base64AuthInfo'  -Type NoteProperty -Value "$b" }
    
  return $t_resp
}

#-----------------------------------------------------------------
Function P2V_get_userlist($tenant)
{ # function to retrieve P2V userlist from tenant
   $tenantURL       ="$($tenant.ServerURL)/$($tenant.tenant)"
   $base64AuthInfo  ="$($tenant.base64AuthInfo)"
   $API_URL         ="$tenantURL/PlanningSpace/api/v1/users?include=UserWorkgroups"
   $t               = $tenant.tenant
   $refresh_list    = $true       # default to refresh list
   $cur_date        = (get-date)
   $max_age_minutes = 3     # max age of list in minutes
   $user_list       = @{}
   
   write-log 
   write-output ($form3 -f $t, $($P2V_userlist[$t].createdate), $($P2V_userlist[$t].count))
   if ($P2V_userlist[$t])
   {
	   write-output ($form3 -f  $t  ,$($P2V_userlist[$t].createdate))
  	  if (($cur_date -$($P2V_userlist[$t].createdate)).totalminutes -gt $max_age_minutes) 
	  { 
	     $refresh_list   = $true  
		 clear-variable $($P2V_userlist[$t])
      } else 
	  { $refresh_list   = $false }
   } 
   else    { $refresh_list   = $true }
   
   if ($refresh_list)
   {
        write-progress -Activity "loading userlist from tenant $t"
		write-log "loading userlist from tenant $t"
		$user_list=Invoke-RestMethod -Uri $API_URL -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
        if (!$user_list) {$form_err -f "[ERROR]", "cannot contact $t !" ;exit}
		write-progress -Activity "loading userlist from tenant $t" -completed
		$P2V_userlist[$t]=New-Object PSObject -Property @{
		                               createdate = $cur_date
									   list       = $user_list 
									   }
   }
   write-output "checking Tenant-lists"
   foreach ($i in $P2V_userlist.keys)
	{
    $P2V_userlist[$i].list | Out-GridView -Wait -Title "$i/$($P2V_userlist[$i].createdate)"
	}

   # return $user_list
   return $($P2V_userlist[$t].list)
}

#-----------------------------------------------------------------
Function get_PS_userlist($tenant)
{ #get-userlist from Planningspace $tenant  - OLD VERSION
  
  ask_continue -title "old code detected" -msg "Warning $([System.Environment]::NewLine)old function [get_PS_userlist] used!$([System.Environment]::NewLine) consider changing it to [P2V_get_userlist]." -button 0 -icon 48
  
  return (P2V_get_userlist($tenant))
  
 }

#-----------------------------------------------------------------
Function P2V_change_user_status 
{
	param (
	     [string]$xkey="",    
         [Object[]]$tenants,
		 [bool]$changelock=$false,
		 [bool]$lock=$false ,
		 [bool]$changedeactivate=$false,
	     [bool]$deactivate=$false
	 )
	
	
    #  select_user from AD
	write-output ($form1 -f "in P2V_change_user_status  xkey= [$xkey]")
	write-output ($form1 -f "in [$($MyInvocation.MyCommand)]  xkey= [$xkey]  debug=[$debug]")
	$selected_user = get_AD_user -xkey $xkey 
	$activity_date=(Get-date -format "[dd/MM/yyyy]")
	
	# select tenant 
	if (!$tenants) { $tenants_sel = select_PS_tenants }
	
    		
	
	foreach ($ts in $tenants_sel.keys)
	{
		$t               = $tenants_sel[$ts]
        $tenant          = $t.tenant
        $tenantURL       = "$($t.ServerURL)/$($t.tenant)"
        $base64AuthInfo  = $t.base64AuthInfo   
	    $accessgroup     = $t.ADgroup

        $updateUserOperations =@()
		$temp_operation = @()
  
		$message         = "user [{0, 10}] will be [{1, 5}] in tenant [{2, 5}]"
		$message2        = ""
		
		# get user (UPN=LogONId) from tenant
		$P2V_user=P2V_get_userlist $t |  where-Object {($($_.logOnId) -eq $($selected_user.UserPrincipalName)) }
		
		write-output $linesep
		write-output $P2V_user
		write-output $linesep
		
		if ($changelock)
		{
			if ($lock) {$activity="locked"}
			    else   {$activity="unlocked"}
			
			$updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/isAccountLocked"
                    value = $lock
               }
			
		}
	
	    if ($changedeactivate)
		{
						
			if ($deactivate) 
			   {
				  $activity="deactivated";
				  if ($P2v_user.isDeactivated)
				  {				  
				    $message2=" user already deactivated - skipping activity"
				  }
				  else
				  {
				    $temp_operation += [PSCustomObject]@{
					 op    = "replace"
					 path  = "/userWorkgroups"
					 value = @{}
				  }
							
			   	    $temp_operation += [PSCustomObject]@{
					 op    = "replace"
					 path  = "/description"
					 value = "[DEACTIVATED] $($P2V_user.description)"
				    }
				  
			        $updateUserOperations += [PSCustomObject]@{
                     op    = "replace"
                     path  = "/isDeactivated"
                     value = $deactivate
                    }
				  }					
			
			   }
			else         
			   {
				  $activity="activated"
				
			      $updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/isDeactivated"
                    value = $deactivate
                  }		
				
		        }
				
		}
		
		write-output ($form1 -f ($message -f $($selected_user.displayName),$activity, $tenant))
		write-output ($form1 -f $message2)
		#ask_continue -title "DEBUG" -msg "click OK to start wave 1 : 'n $temp_operation"
		# wave 1  to empty workgroups before deactivating
		write-output ($form1 -f "--> $tenant <--")
		if ($temp_operation.Count -gt 0)
            {
               
               $body= $temp_operation| ConvertTo-Json
			   if ($temp_operation.Count -eq 1 ) {$body = "[ $body ]"}
			   write-debug ($form1 -f "$tenantURL/PlanningSpace/api/users/$($P2V_user.id)")
			   write-debug $body
			   write-debug $linesep
			   write-debug "temp_operation"|out-host
	              
			    #$check=
				$check =Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/users/$($P2V_user.id)" -Method PATCH -Headers @{'Authorization' = "Basic $base64AuthInfo"}  -Body ( $body ) -ContentType "application/json"
                
				
               if ($check) { write-output ($check|ConvertTo-Json) }
	    		 		   
            }
					
		#ask_continue -title "DEBUG" -msg "click OK to continue with wave2 'n updateUserOperations "
		# main changes 
		write-output $linesep
		
		if ($updateUserOperations.Count -gt 0 )
            {
               
               $body= $updateUserOperations| ConvertTo-Json
			   if ($updateUserOperations.Count -eq 1 ) {$body = "[ $body ]"}
			    write-debug ($form1 -f "$tenantURL/PlanningSpace/api/users/$($P2V_user.id)")
			   write-debug $body
			   write-debug $linesep
			   write-debug "updateUserOperations"|out-host
			   
        
			   $check=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/users/$($P2V_user.id)" -Method PATCH -Headers @{'Authorization' = "Basic $base64AuthInfo"}  -Body "$body" -ContentType "application/json"
   
               if ($check) { write-output ($check|ConvertTo-Json) }
			    				   

            }
		
	}
	
}

#-----------------------------------------------------------------
Function P2V_lock_user
{
	param (
	     [string]$xkey="",    
         [Object[]]$tenants=""
		 )
	
	write-output ($form1 -f "in P2V_lock_user")
	return (P2V_change_user_status -xkey $xkey -tenants $tenants -changelock $true  -lock $true -changedeactivate $false -deactivate $false )
}

#-----------------------------------------------------------------
Function P2V_unlock_user
{
	param (
	     [string]$xkey="",    
         [Object[]]$tenants=""
		 )
	write-output ($form1 -f "in P2V_unlock_user")
	return (P2V_change_user_status -xkey $xkey -tenants $tenants -changelock $true  -lock $false -changedeactivate $false -deactivate $false )
	
	
}

#-----------------------------------------------------------------
Function P2V_deactivate_user
{
	param (
	     [string]$xkey="" ,   
         [Object[]]$tenants=""
		 )
	write-output ($form1 -f "in P2V_deactivate_user")
	
	#P2V_change_user_status -xkey $xkey -tenants $tenants -changelock $false  -lock $false -changedeactivate $true -deactivate $false
	return (P2V_change_user_status -xkey $xkey -tenants $tenants -changelock $false  -lock $false -changedeactivate $true -deactivate $true )
	
	
}

#-----------------------------------------------------------------
Function P2V_activate_user
{
	param (
	     [string]$xkey="" ,   
         [Object[]]$tenants=""
		 )
	write-output ($form1 -f "in P2V_activate_user")
	return (P2V_change_user_status -xkey $xkey -tenants $tenants -changelock $false  -lock $false -changedeactivate $true -deactivate $false )
	
	
}

#-----------------------------------------------------------------
Function NEW_P2V_super_sync
{
	param(
    [string] $xkey = "",
    [bool]  $debug= $false
  )
  $VerbosePreference = "Continue"
  #  select_user from AD
  write-output ($form1 -f "in [$($MyInvocation.MyCommand)]  xkey= [$xkey]  debug=[$debug]")
  
  if (($xkey) -or ($cont=get_AD_user_GUI -title "P2V sync user") -eq "OK" )
  {
      $user_selected=$global:usr_sel
	Write-Output -NoEnumerate ($form1 -f "user selected: $($user_selected.displayname)")
    Write-Output -NoEnumerate ($form1 -f "assigned profiles")
    
	$u_xkey=$($user_selected.SAMAccountName)
    $u_logonID=$($user_selected.UserPrincipalName)  
  

  }
  
	
	
}
#-----------------------------------------------------------------
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

#-----------------------------------------------------------------
Function P2V_calculate_groups_bd
{
param(
  [string]$allow="",
  [string]$readonly="",
  [string]$deny="",
  [string]$tenant="",
  [bool]$checkonly = $FALSE,
  #[bool]$checkonly = $true,
  [bool]$skip_local = $TRUE,
  [bool]$debug = $false
  
)
#-----------------------------------------------------------------
function Get-UserADGroups {
    param([string]$SamAccountName)
    try {
        Get-ADPrincipalGroupMembership -Identity $SamAccountName | Select -ExpandProperty Name
    } catch {
        Write-P2VDebug "Get-ADPrincipalGroupMembership failed for $SamAccountName: $($_ | Out-String)"
        # Fallback: enumerate group membership manually
        Get-ADUser $SamAccountName -Properties MemberOf | Select-Object -ExpandProperty MemberOf |
            ForEach-Object { ($_ -split ',')[0] -replace '^CN=' }
    }
}
Export-ModuleMember -Function Get-UserADGroups

#-----------------------------------------------------------------
#----- Set config variables

$output_path = $output_path_base + "\$My_name"
$P2V_U      = @{}   # userlist  from P2V
$P2V_U_sel  = @{}   # selected userlist  from P2V_U
$P2V_G      = @{}   # grouplist from P2V
$P2V_UG	    = @{}   # U-G assignment
# -> move inside TENANT LOOP  :$updateOperations   = @{}   # change-operations  for bulk load based on groups
$change_ops = @{}
$temp_ops= @{}

# from P2V_include:
# $data_groups
# $bd_assign_file
# $bd_project_file


P2V_header -app $MyInvocation.MyCommand -path $My_path 


$bd_proj_users   = @{}     # list of users per project    xx[bd-proj]= list of users            bd_assignments
$bd_user_projs   = @{}     # list of projects per user    xx[user] = list of projects           bd_user_assign
$all_bd_def       = @{}    # list of BD-project including names, description
$all_bd_assign    = @{}    # list of BD-project - user assignments
$bd_group_members = @{}
$bd_sel           = @{}
$bd_base_members  = @()

# standard group to base access BD-version in Dataflow
$bd_base_group    = "bd.base"

# load all BD project definitionsassignments (allows)
write-output  ($form1 -f "loading BD project definition file [$bd_project_file]")
write-progress  "loading BD project definition file  $bd_project_file"

$all_bd_def= import-csv $bd_project_file -Encoding UTF8|Sort-Object -Property BDID

# load all user <> BD assignments (allows)
write-output  ($form1 -f "loading BD project assignment file [$bd_assign_file]")
write-progress  "loading BD project assignment file  $bd_assign_file"

$all_bd_assign= import-csv $bd_assign_file -Encoding UTF8|Sort-Object -Property BDID

write-output  ($form1 -f "loading BD project assignment from Active Directory")
write-progress  "loading BD project assignment from Active Directory"

Foreach ($bd in $all_bd_def)
{
	if ($($bd.ADgroup)) 
	{
		write-output  ($form1 -f "        [$($bd.ADgroup)]")|out-host
 		foreach ($u in (get-adgroupmember -identity $($bd.ADgroup) |select name))
		{
			write-progress "loading $($bd.ADgroup) / $u"
			$loc_user= Get-aduser -identity $u.name -properties * |select samaccountname,UserPrincipalName
		    $all_bd_assign += [PSCustomObject] @{
			    BDID    = $bd.BDID
			    xkey    = $loc_user.SAMAccountName
			    logonID = $loc_user.UserPrincipalName
			    reason  = "ADgroup $($bd.ADgroup)"
		    }		
		}
		write-progress "loading $($bd.ADgroup)" -completed
	}
}	

$ALL_BD_ASSIGN |Export-Csv -path "$dashboard_path\bd_assignments.csv" -NoTypeInformation 

# do not touch these accounts
$bd_exclude = @( "Administrator" , 
				 "Reserves_service" , 
				 "Reporting" , 
				 "PBI.corporate" , 
				 "PBI.corporate.BD" )

# later on :
# $bd_exclude= Get-Content -Path $bd_exclude_file

#  select which BD projects to sync

$all_bd_def|out-gridview -title "which BD projects to sync ?" -PassThru |% {$bd_sel["$($_.BDID)"]=$_}

if ($debug) 
{ 
  write-output "ALL_BD_ASSIGN:"
  # $all_bd_assign|format-table 
  $linesep;
  if (! ($cont=ask_continue -title "Continue 1?" -msg "Do you want to continue ?")) {write-warning "exiting on request"; exit}
}

foreach ($bd in $all_bd_assign|sort)
{
	write-progress "checking $($bd.BDID)"
   if ($bd_sel.keys -contains $bd.BDID )	
   {
      
    $bd_proj_users["$($bd.BDID)"]    += @($bd.logonID)
    $bd_user_projs["$($bd.logonID)"] += @($bd.BDID)
      
    if (! ($bd_base_members -contains $bd.logonID)) { $bd_base_members += @($bd.logonID) }
   
   }
	
}


write-progress "generating activity list"

foreach ($bd in $bd_proj_users.keys|sort)
{
  $bd_group_members[$bd]= [PSCustomObject]@{
           allow=$bd_proj_users[$bd]
		   deny=@()
		   }
  #$bd_group_members[$bd]|add-member -Name "deny"  -Type Noteproperty -Value @()
}

if ($debug) 
{
    write-output "bd_proj_users:"
	 
    $bd_proj_users|ft
    $linesep;
	write-output "BD_SEL:"
	$bd_sel|ft
	$bd_base_members| out-gridview -wait
	
     if (! (ask_continue -title "Continue 2?" -msg "Do you want to continue ?")) {write-warning "exiting on request"; exit}

}
write-progress "generating activity list" -completed
#$linesep
#$bd_group_members|ft
#pause
$tenants= select_PS_tenants -multiple $true

foreach ($ts in $tenants.keys)
{
  $t               = $tenants[$ts]
  $tenant          = $t.tenant
  $tenantURL       = "$($t.ServerURL)/$($t.tenant)"
  $base64AuthInfo  = $t.base64AuthInfo      
  $acount          = 0
  $dcount          = 0
  $updateOperations   = @{}   # change-operations  for bulk load based on groups
   
  write-output ($form1 -f ">> checking $tenant")
   
  $all_users = P2V_get_userlist -tenant $t 
  
  $all_users = $all_users|where { ($_.IsDeactivated -ne $true) }     # skip deactivated users
  
  if ($skip_local) { $all_users = $all_users | where { ($_.authenticationMethod -eq "SAML2") }}  # skip local 
  
      
  $all_users  | % {$P2V_U["$($_.logonID)"]=$_}
   
  $all_groups= get_PS_grouplist -tenant $t 
  $all_groups | % {$P2V_G["$($_.name)"]=$_}
  
  $all_users |out-gridview -Title "[$tenant] select user(s)" -PassThru  | % {$P2V_U_sel["$($_.logonID)"]=$_}
  
  
  if ($debug) {$P2V_U_sel|out-gridview -wait }
  
  foreach ($currentuser in $P2V_U_sel.keys)
  {
	write-progress "checking $currentuser"	  
    # default  - bd.deny
		 	 	 
    #$p2v_u[$currentuser]|format-list
	  
    foreach($tmpgroups in $P2V_U[$currentuser].userWorkgroups)
    {
   	   $tmpgroups | Get-Member -MemberType Properties | select -exp "Name" | % { $P2V_UG[$currentuser]+= @($($tmpgroups | SELECT -exp $_).name)  }
    }
	 
    $bd_base= ($bd_base_members -contains $currentuser)
      	 
	$uid=$P2V_U["$currentuser"].id
	 
	# loop all BD -project IDs
	
	foreach ($bd in $bd_proj_users.keys)
	{
	  $activity=""
	  $g_a = "$bd.allow"
	  $g_d = "$bd.deny"
	  #write-progress -nonewline "$($t.tenant):[$bd]"
	  #write-progress "$($t.tenant):[$bd]"
	  	
	    # check if user is allowed 
		
#		write-output ($form2_2 -f "$currentuser : $($t.tenant)","[$bd]") |out-host
		
	    if ($bd_proj_users[$bd] -contains $currentuser)
		{ # -> User is allowed -> add to .allow group , remove from .deny group
			   
               $bd_base = $bd_base -or $true
			   if ($P2V_UG["$currentuser"] -contains $g_a) 
			   { #as-is: Allow+ to-be Allow+ -> SKIP
		#	     $form_status -f "$currentuser == $g_a","[SKIP]"
			   }
               else 
			   { #as-is: Allow- to-be Allow+ -> ADD
			 
		         write-output (  $form3_2 -f "$currentuser","$g_a","[ADD]")
			     $change_ops  = [PSCustomObject]@{
					    workgroup   = $g_a
					    displayName = $P2V_U[$currentuser].displayName
						logOnId     = $P2V_U[$currentuser].logOnId
                        op 			= "add"
                        path 		= "/users/$uid"
                        value 		= ""}
				 $updateOperations["$g_a"]+= @($change_ops)
				 $acount++
			   }
               if ($P2V_UG["$currentuser"] -contains $g_d) 
			   { #as-is: Deny+ to-be Deny- -> DEL
  		         write-output ( $form3_2 -f "$currentuser","$g_d","[DEL]")
				 $change_ops  = [PSCustomObject]@{
					    workgroup   = $g_d
					    displayName = $P2V_U[$currentuser].displayName
						logOnId     = $P2V_U[$currentuser].logOnId
                        op 			= "remove"
                        path	 	= "/users/$uid"
                        value 		= ""
                 }
				 $updateOperations["$g_d"]+= @($change_ops)
				 $dcount++
			   }
			   else 
			   {#as-is: Deny- to-be Deny- -> SKIP
		#	     $form_status -f "$currentuser != $g_d","[SKIP]"
			   }
		   
		}
		else
		{ # -> User is NOT allowed -> add to .deny group , remove from .allow groupDENY
    
			  $bd_base = $bd_base -or $false # no function ;-) 
 			 
              if ($P2V_UG["$currentuser"] -contains $g_a) 
			  { #as-is: Allow+ to-be Allow- -> DEL
  		        write-output( $form3_2 -f "$currentuser","$g_a","[DEL]")
				$change_ops  = [PSCustomObject]@{
					  workgroup   = $g_a
					  displayName = $P2V_U[$currentuser].displayName
						logOnId   = $P2V_U[$currentuser].logOnId
                              op  = "remove"
                            path  = "/users/$uid"
                           value  = ""
			     }
				$updateOperations["$g_a"]+= @($change_ops)
				$dcount++
			  }
			  else 
			  { #as-is: Allow- to-be Allow- -> SKIP
		#	    $form_status -f "$currentuser != $g_a","[SKIP]"
			  }			 
			  
              if ($P2V_UG["$currentuser"] -contains $g_d) 
			  { #as-is: Deny+ to-be Deny+ -> SKIP
		#	    $form_status -f "$currentuser == $g_d","[SKIP]"
			  }
			  else 
			  { #as-is: Deny- to-be Deny+ -> ADD
  		        write-output ( $form3_2 -f "$currentuser","$g_d","[ADD]")
				$change_ops  = [PSCustomObject]@{
					  workgroup   = $g_d
					  displayName = $P2V_U[$currentuser].displayName
					  logOnId     = $P2V_U[$currentuser].logOnId
                      op 		  = "add"
                      path = "/users/$uid"
                      value = ""}
			    $updateOperations["$g_d"]+= @($change_ops)
				$acount++
			  }
			  $bd_group_members[$bd].deny += @($currentuser)
		}      
	}

	 if ($P2V_UG["$currentuser"] -contains $bd_base_group) 
	 { # user already has base  BD access
	   if ($bd_base) 
	   {
	#    $form_status -f "$currentuser == $bd_base_group","[SKIP]"
	   }
	   else          
	   {
	write-output (	   $form3_2 -f "$currentuser","$bd_base_group","[DEL]")
		 $change_ops  = [PSCustomObject]@{
					   workgroup = $bd_base_group
					 displayName = $P2V_U[$currentuser].displayName
						logOnId  = $P2V_U[$currentuser].logOnId
                              op = "remove"
                            path = "/users/$uid"
                           value = ""
			     }
		 $updateOperations["$bd_base_group"]+= @($change_ops)
		 $dcount++
	   }
	 } else
	 { # user  has NO base  BD access yet
	    if ($bd_base) 
		{
	write-output (	   $form3_2 -f "$currentuser","$bd_base_group","[ADD]")
		   $change_ops  = [PSCustomObject]@{
			          workgroup   = $bd_base_group
  					  displayName = $P2V_U[$currentuser].displayName
						logOnId   = $P2V_U[$currentuser].logOnId
						op        = "add"
                          path    = "/users/$uid"
                         value    = ""}
			$updateOperations["$bd_base_group"]+= @($change_ops)			    
			$acount++
		}
	   else   
       {
	 #     $form_status -f "$currentuser != $bd_base_group","[SKIP]"
	   }         
	 }
	}
   write-progress "checking users completed" -completed
   write-output $linesep 
   foreach ( $k in $bd_proj_users.keys)
   { 
     $ka= "$k.allow"
	 $kd= "$k.deny"
	  	
     $output="group: {0,-15} total: {1,4} ops needed: {2,4}"
	     
     $a1=$output -f "$k.allow","$($bd_group_members[$k.tostring()].allow.count)","$($updateOperations[$ka].count)"
	 $d1=$output -f "$k.deny","$($bd_group_members[$k.tostring()].deny.count)","$($updateOperations[$kd].count)"
 	
	 write-output ($form2_2 -f "$a1", "$d1")
   }
		
	write-output ($form1 -f "total required operations:   ADD: $acount  DEL: $dcount")
		
	#----
	$do_all   = $false
	$skip_all = $false
	$do_it    = $false
    $temp_list = @()
	$temp_ops2 = @{}
    foreach ($i in $updateOperations.keys)
	{
		  $temp_list += @($updateOperations[$i])
	}
	
	$updateOperations = @{}
	
	$temp_list|out-gridview -title "select activities for $i"  -PassThru  | % {$updateOperations["$($_.workgroup)"]+=@($_)}
	
	#$updateOperations = $temp_ops2
	
	
	$updateOperations|out-gridview -wait
	
	foreach ($i in $updateOperations.keys)
    {
        if ($updateOperations[$i].Count -gt 0) 
		{
			$temp_ops=$updateOperations[$i]
		    write-output $linesep 
            if ((! $do_all) -and (! $skip_all))
			{
			  #$cont=read-host ($form1 -f "add [$($updateOperations[$i].Count)] user/workgroup assignments to $i (Yes/No/All)")
			  $temp_ops= $updateOperations[$i]|out-gridview -title "select activities for $i" -outputmode multiple
			  
			  
			  if ($temp_ops.Count -gt 0) 
			  {
			  $cont=ask_YesNoAll -title "Apply changes?" -msg " add [$($temp_ops.Count)] user/workgroup assignments to $i ?"
			  #$cont=$cont.trim()
		      write-output ($form1 -f "[$cont] selected")
			  switch ($cont)
			  {
                 Yes    {$do_it =$true; Break}
			     OK     {$do_it =$true;  $do_all=$true; Break}
			     No     {$do_it =$false; Break}
			     Abort  {$do_it =$false; $skip_all=$true; Break}
              }
			  }
            }   			  
			  
			if ($do_it -or $do_all)
            {			
                $line= "changes applied to $i : $($temp_ops.op) $($temp_ops.displayName)"
		        $gid=$($P2V_G[$i].id)
			    
				write-output "$temp_ops"
				write-output $temp_ops.count
				
                $body=$temp_ops|Select-Object -Property * -ExcludeProperty displayName,logOnId |convertto-json		
			    
				if ($($temp_ops.count) -eq 1 ){ $body= "[ $body ]" }
				
           # [System.Windows.Forms.MessageBox]::Show($body ,"JSON-changes",0)
  
                $apiUrl = "$($tenantUrl)/planningspace/api/v1/workgroups/$gid"	
				
				write-output "Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers @{'Authorization' = ""Basic $base64AuthInfo""} -Body ( $body ) -ContentType ""application/json"""
                $i_result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ( $body ) -ContentType "application/json"
				
				
#               $i_result
               if ($i_result) 
                  { $form_status -f  $line, "[DONE]"
				    write-log "[$tenant]-[$i] : $($temp_ops.op) $($temp_ops.displayName) - done"
				  } else
                  { $form_status -f  $line, "[ERROR]"
				    write-log -logtext "[$tenant]-[$i] : $($temp_ops.op) $($temp_ops.displayName) - error" -level 2
				  } 
				  
				  
				  
            } else {$form1 -f "no changes done to $i"}
        } else {$form1 -f "no changes needed"}
	}
    $linesep
}

	
 P2V_footer -app $MyInvocation.MyCommand
}
#


#=================================================================
# Exports
#=================================================================

Export-ModuleMember -Variable *
Export-ModuleMember -Function * -Alias *
