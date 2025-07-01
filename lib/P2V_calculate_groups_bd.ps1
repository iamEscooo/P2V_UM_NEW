#=======================
#  calculate_group_bd
#
#  name:   calculate_group_bd.ps1 
#  ver:    1.0
#  author: M.Kufner
#=======================
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

#----- Set config variables

$output_path = $output_path_base + "\$My_name"
$P2V_U      = @{}   # userlist  from P2V
$P2V_U_sel  = @{}   # selected userlist  from P2V_U
$P2V_G      = @{}   # grouplist from P2V
$P2V_UG	    = @{}   # U-G assignment
$updateOperations   = @{}   # change-operations  for bulk load based on groups
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
write-output  "loading BD project definition file  $bd_project_file"
write-progress  "loading BD project definition file  $bd_project_file"

$all_bd_def= import-csv $bd_project_file -Encoding UTF8|Sort-Object -Property BDID


# load all user <> BD assignments (allows)
write-output  "loading BD project assignment file  $bd_assign_file"
write-progress  "loading BD project assignment file  $bd_assign_file"



$all_bd_assign= import-csv $bd_assign_file -Encoding UTF8|Sort-Object -Property BDID

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
   }
   
    if (! ($bd_base_members -contains $bd.logonID)) { $bd_base_members += @($bd.logonID) }
}

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
   
  write-output ($form1 -f ">> checking $tenant")
   
  $all_users = get_PS_userlist -tenant $t 
  
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
# ----- end of file -----

