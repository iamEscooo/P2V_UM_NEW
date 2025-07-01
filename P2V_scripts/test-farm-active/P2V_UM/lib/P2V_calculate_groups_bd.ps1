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
  [bool]$debug = $false
)

#----- Set config variables

$output_path = $output_path_base + "\$My_name"
$P2V_U      = @{}   # userlist  from P2V
$P2V_G      = @{}   # grouplist from P2V
$P2V_UG	    = @{}   # U-G assignment
$updateOperations   = @{}   # change-operations  for bulk load based on groups
$change_ops = @{}

# from P2V_include:
# $data_groups
# $bd_groups

 P2V_header -app $MyInvocation.MyCommand -path $My_path 
 
$bd_assignments= @{}
$all_bd= @{}
$bd_group_members= @{}

# standard group to base access BD-version in Dataflow
$bd_base_group="bd.base"

# load all user <> BD assignments (allows)
$all_bd= import-csv $bd_groups -Encoding UTF8|Sort-Object -Property BDID

# do not touch these accounts
$bd_exclude = @( "Administrator" , 
				 "Reserves_service" , 
				 "Reporting" , 
				 "PBI.corporate" , 
				 "PBI.corporate.BD" )

# later on :
# $bd_exclude= Get-Content -Path $bd_exclude_file
if ($debug) 
{ $all_bd|format-table 
  $linesep;
}

foreach ($bd in $all_bd)
{
  $bd_assignments["$($bd.BDID)"]+=@($bd.logonID)
}
foreach ($bd in $bd_assignments.keys|sort)
{
  $bd_group_members[$bd]= [PSCustomObject]@{
           allow=$bd_assignments[$bd]
		   deny=@()
		   }
  #$bd_group_members[$bd]|add-member -Name "deny"  -Type Noteproperty -Value @()
}

if ($debug) 
{ $bd_assignments|ft
$linesep;
pause
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
  # $all_users = $all_users|where { ($_.authenticationMethod -eq "SAML2") }
  $all_users = $all_users|where { ($_.IsDeactivated -ne $true) }
  $all_users  | % {$P2V_U["$($_.logonID)"]=$_}
   
  $all_groups= get_PS_grouplist -tenant $t 
  $all_groups | % {$P2V_G["$($_.name)"]=$_}
   
  foreach ($currentuser in $P2V_U.keys)
  {
    # default  - bd.deny
	if ($bd_exclude -contains $currentuser) {continue}
	 	 	 
    #$p2v_u[$currentuser]|format-list
	  
    foreach($tmpgroups in $P2V_U[$currentuser].userWorkgroups)
    {
   	   $tmpgroups | Get-Member -MemberType Properties | select -exp "Name" | % { $P2V_UG[$currentuser]+= @($($tmpgroups | SELECT -exp $_).name)  }
    }
	 
	$bd_base=$false
      	 
	$uid=$P2V_U["$currentuser"].id
	 
	# loop all BD -project IDs
	foreach ($bd in $bd_assignments.keys)
	{
	  $activity=""
	  $g_a = "$bd.allow"
	  $g_d = "$bd.deny"
	  write-host -nonewline "$($t.tenant):[$bd]`r"
	  	
	    # check if user is allowed 
	    if ($bd_assignments[$bd] -contains $currentuser)
		{ # -> User is allowed -> add to .allow group , remove from .deny group
			   
               $bd_base = $bd_base -or $true
			   if ($P2V_UG["$currentuser"] -contains $g_a) 
			   { #as-is: Allow+ to-be Allow+ -> SKIP
		#	     $form_status -f "$currentuser == $g_a","[SKIP]"
			   }
               else 
			   { #as-is: Allow- to-be Allow+ -> ADD
			 
		         write-output (  $form_status -f "$currentuser += $g_a","[ADD]")
			     $change_ops  = [PSCustomObject]@{
                            op = "add"
                          path = "/users/$uid"
                         value = ""}
				 $updateOperations["$g_a"]+= @($change_ops)
				 $acount++
			   }
               if ($P2V_UG["$currentuser"] -contains $g_d) 
			   { #as-is: Deny+ to-be Deny- -> DEL
  		         write-output ( $form_status -f "$currentuser -= $g_d","[DEL]")
				 $change_ops  = [PSCustomObject]@{
                              op = "remove"
                              path = "/users/$uid"
                              value = ""
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
  		        write-output( $form_status -f "$currentuser -= $g_a","[DEL]")
				$change_ops  = [PSCustomObject]@{
                              op = "remove"
                            path = "/users/$uid"
                           value = ""
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
  		        write-output ( $form_status -f "$currentuser += $g_d","[ADD]")
				$change_ops  = [PSCustomObject]@{
                            op = "add"
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
	write-output (	   $form_status -f "$currentuser -= $bd_base_group","[DEL]")
		 $change_ops  = [PSCustomObject]@{
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
	write-output (	   $form_status -f "$currentuser += $bd_base_group","[ADD]")
		   $change_ops  = [PSCustomObject]@{
                            op = "add"
                          path = "/users/$uid"
                         value = ""}
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
   foreach ( $k in $bd_assignments.keys)
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
	foreach ($i in $updateOperations.keys)
    {
        if ($updateOperations[$i].Count -gt 0) 
		{
		    write-output $linesep 
            if ((! $do_all) -and (! $skip_all))
			{
			  #$cont=read-host ($form1 -f "add [$($updateOperations[$i].Count)] user/workgroup assignments to $i (Yes/No/All)")
			  $cont=ask_YesNoAll -title "Apply changes?" -msg " add [$($updateOperations[$i].Count)] user/workgroup assignments to $i ?"
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
			  
			if ($do_it -or $do_all)
            {			
                $line= "changes applied to $i "
		        $gid=$($P2V_G[$i].id)
			 
                $body=$updateOperations[$i]|convertto-json		
			    if ($($updateOperations[$i].count) -eq 1 ){ $body="[ $body ]" }
      #       $body
      #      pause
                $apiUrl = "$($tenantUrl)/planningspace/api/v1/workgroups/$gid"	
                $i_result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ( $body ) -ContentType "application/json"
#               $i_result
               if ($i_result) 
                  {$form_status -f  $line, "[DONE]"} else
                  {$form_status -f  $line, "[ERROR]"} 
            } else {$form1 -f "no changes done to $i"}
        } else {$form1 -f "no changes needed"}
	}
    $linesep
}

	
 P2V_footer -app $MyInvocation.MyCommand
}
# ----- end of file -----

