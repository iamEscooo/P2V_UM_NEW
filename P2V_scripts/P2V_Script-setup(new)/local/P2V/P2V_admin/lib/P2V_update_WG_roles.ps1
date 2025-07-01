#-----------------------------------------
# P2V_update_WG_roles.ps1
#-----------------------------------------
param(
    [string]$workingDir = "\\somvat202005\PPS_share\P2V_UM_data\",
    [bool]$analyzeOnly = $True
)

<#  documentation
.SYNOPSIS
	P2V_update_WorkgroupRolesFromCsv reads a config file  to read list 
	of <old name> <new name> records and apply changes to selected tenant
.DESCRIPTION
	P2V_super_sync read AD group memberships, translate them in P2V-workgroup assignments
	and updates the selected P2V tenant

.PARAMETER ??? menufile <filename>  
	CSV file 
	
.PARAMETER ??? xamldir <directory>
	CSV file 
	
.PARAMETER ??? fcolor  <colorcode>
	foregroundcolor of menubuttons  
    colorcode = colorname like 'lightblue'  or HEXcode like #003366"

.PARAMETER ??? bcolor  <colorcode>
	backgroundcolor of menubuttons  
    colorcode = colorname like 'lightblue'  or HEXcode like #003366"

.INPUTS
	config file
.OUTPUTS
	true / false

.EXAMPLE
	Example of how to run the script.

.LINK
	Links to further documentation.

.NOTES
  name:   P2V_super_sync.ps1 
  ver:    1.0
  author: M.Kufner

  approach:
  1) ADgroups -> systemaccess /user     (< adgroups.csv)
  2) ADgroups -> profiles / user        (< adgroups.csv)
  3) user:profiles -> user:workgroups   (< profiles.csv)
  4) 
  
  --
  data structure:
  $to_be_list= @{}
  
  $to_be_list ["workgroupname"} = {
       id    = workgroupID
       name  = workgroupNAME
       roles = @( list of roles = {rid = roleID, name= roleName))
       }
 
#>

#-------------------------------------------------
$My_name=$($MyInvocation.MyCommand.Name)
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir\P2V_include.ps1"
. "$workdir\P2V_forms.ps1"
$user=$env:UserDomain+"/"+$env:UserName 

#------------------ START OF SCRIPT LOGIC -----------------------------

# Log summary of passed parameters
cls

P2V_header -app $My_name -path $My_Path

do{
Write-Output "|> select workgroup <> roles assignment file:  "
$WorkgroupRolesFromCsv_File = Get-FileName ($workingDir)
Write-Output "[$WorkgroupRolesFromCsv_File]"
}until(($cont=read-host ("continue with selected file (y/n)")) -like "y")

# Load CSV files
$form1 -f "Loading from input CSV file [$WorkgroupRolesFromCsv_File]..."

$changesFromCsv=@{}
$changesFromCsv=Import-Csv $WorkgroupRolesFromCsv_File

# format: tenant,workgroup,GID,Category_1,Name,Description,Application name,Category,RID

$WorkgroupRolesFromCsv=@{}
if ($debug)
{
 write-debug "changesFromCsv:"
  $changesFromCsv|ft|out-host
  pause
} 
  
$linesep|out-host
write-output ($form1 -f " STEP 1 - get TO-BE from $WorkgroupRolesFromCsv_File")
# write-output ($form_wg_r -f "GID","WGname","AS-IS","TO-BE","ACTION","RID","Role")
$linesep|out-host
foreach ($l in $changesFromCsv) 
 {  # TO-BE from .csv file
     if ($WorkgroupRolesFromCsv.keys -contains $($l.workgroup) )
     { # group already exists in list
     	  
		if ($WorkgroupRolesFromCsv[$l.workgroup].GID -eq $l.GID -and $WorkgroupRolesFromCsv[$l.workgroup].WGName -eq $l.workgroup)
     	{ # check if ID and name are matching
     		 		 
			if ($WorkgroupRolesFromCsv[$l.workgroup].tobe -contains $l.RID)
     		{ # check if double entries
	#		write-output ($form_wg_r -f $l.GID, $l.Workgroup,"[ ? ]","[ x ]","", $l.RID,$l.Description)
			#	write-output "GID: $l.GID  WGName: $l.WGName RID: $l.RID ";
     		 	$WorkgroupRolesFromCsv[$l.workgroup].tobe|out-host
     		} else
     		{
	#		write-output ($form_wg_r -f $l.GID, $l.Workgroup,"[ ? ]","[ x ]","[ADD]", $l.RID,$l.Description)
     		  	#write-output ($form1 -f "GID: $($l.GID)  WGName: $($l.workgroup) Role:  $($l.RID)/$($l.Description) [ADD]")
     		   	#write-output ($form3 -f "",$l.RID,$l.Description)
   
 	            $WorkgroupRolesFromCsv[$l.workgroup].tobe += $l.RID	 	    	
    	   	}  	   		     	
        } else
        {
           	write-output "Error: $($WorkgroupRolesFromCsv[$l.workgroup].GID) -eq $($l.GID) -and $($WorkgroupRolesFromCsv[$l.workgroup].WGName) -eq $($l.workgroup)  "
        } 		 
	 } else
     { #new en
 #      write-output ""
      	$to_be =[PSCustomObject]@{
     	   	     GID        = $l.GID
     	 	     WGName     = $l.workgroup
     	 	     tobe       = @($l.RID)
     	 	     asis       = @()
     }
  #   	write-output ($form_wg_r -f $l.GID, $l.Workgroup,"[ ? ]","[ x ]","[ADD]", $l.RID,$l.Description) 	   
     	$WorkgroupRolesFromCsv[$l.workgroup]=  $to_be

      }
    
 }

$linesep|out-host
#pause
write-output ($form1 -f " STEP 2 - get AS-IS")
write-output ($form_wg_r -f "GID","WGname","AS-IS","TO-BE","ACTION","RID","Role")
$linesep|out-host

# DEBUG: if ($analyzeOnly) { $changesFromCsv|ft ;pause}
#if ($analyzeOnly) { $changesFromCsv|ft ;pause}

$tenants=select_PS_tenants -multiple $true -all $false

# DEBUG: Write-Output $chg_WG
$tenants.keys|% { Write-Output -NoEnumerate ($form1 -f " > $($tenants[$_].tenant)" )}

Write-Output -NoEnumerate ($linesep  )

$WorkgroupsFromTenant= @{}
$RolesFromTenant= @{}

$group_list= @{}
$role_list= @{}
$gid_list= @{}
$rid_list= @{}
$change_ops= @{}
$updateOperations= @{}
$WorkgroupsToSkip= @("Administrators","Everyone","SecurityAdministrators") # default PS workgroups - Everyone to be kept


foreach ($ts in $tenants.keys)
  {
    $t               = $tenants[$ts]
    $tenant          = $t.tenant
    $tenantURL       = "$($t.ServerURL)/$($t.tenant)"
    $base64AuthInfo  = $t.base64AuthInfo   
	$accessgroup     = $t.ADgroup
    # $PS_users= get_PS_userlist -tenant $t
    
    #-- #   read profiles
    #Write-Output -NoEnumerate ($linesep)
	Write-Output -NoEnumerate ($form1 -f ">> checking tenant [$tenant] <<")
	Write-Output -NoEnumerate ($linesep)
	 $group_list=get_PS_grouplist $tenants[$ts]|select id,name,description,allowedRoles
     $group_list|% {$WorkgroupsFromTenant[$($_.name)]=$_ ; $gid_list["$($_.id)"]=$_ }
	
	 $role_list=get_PS_rolelist $tenants[$ts]
	 $role_list|% { $rid_list["$($_.id)"]=$_ }
	 
	#foreach ($r in $rid_list.keys)  {write-output ($form1 -f  "  role: [$($rid_list[$r].id)],$($rid_list[$r].name),$($rid_list[$r].description)") }
	
	foreach ($wg in $WorkgroupsFromTenant.keys)
	{ #foreach workgroup from tenant
		if ($WorkgroupsToSkip -contains $WorkgroupsFromTenant[$wg].name) {continue}
		$element= @{}  
		$element=$WorkgroupsFromTenant[$wg]
		
		$ar_c= $($element.allowedRoles| Get-Member -MemberType Properties | select -exp "Name" ).count
						
		if ($ar_c -gt 0)
		{
	
		   $form3 -f $element.id,$element.name, "#of roles: $ar_c"|out-host	   
           # $form1 -f  $element.allowedRoles
	  	   foreach( $ar in $element.allowedRoles)
           {
		      $hash = @{}  
			  
			  if ( !( $WorkgroupRolesFromCsv.keys -contains $element.name ))
			  {
				$to_be =[PSCustomObject]@{
     	   	              GID        = $element.id
     	 	              WGName     = $element.name
     	 	              tobe       = @()
						  asis       = @()
                }
				$WorkgroupRolesFromCsv[$element.name]=  $to_be
			  }
	
              $ar | Get-Member -MemberType Properties | select -exp "Name" | % { $hash[$_] = ($ar | SELECT -exp $_); $WorkgroupRolesFromCsv[$element.name].asis += $hash[$_].id   }
              #foreach($aro in ($hash.Values | Sort-Object -Property Name)) {$form3 -f "   hash [$($aro.id)]", $($aro.name),$($aro.link) }   
           }
		   
		   #$WorkgroupRolesFromCsv[$element.name].asis +=
		   
	#	    $linesep|out-host
	#	    pause
		}
		if ($WorkgroupsFromTenant[$wg].allowedRoles.count -gt 0)
		{
			 write-output ">> $wg <<"
			 $WorkgroupsFromTenant[$wg].allowedRoles|fl|out-host
		}
	}

	$linesep |out-host
	#$WorkgroupRolesFromCsv|ConvertTo-Json|out-host
	# $linesep |out-host

     # form_wg_r  ="|  {0,-5}/{1,-30}: {2,-5}/{3,-44} {4,-5} {5,-5} {6,-5}" 
	 
	 write-output ($form_wg_r -f "GID","WGname","AS-IS","TO-BE","ACTION","RID","Role")
	 $linesep|out-host
    foreach ( $wg in $WorkgroupRolesFromCsv.keys)
	{
		$element= @{} 
		$element=$WorkgroupRolesFromCsv[$wg]
		
		Write-output ($form1 -f "$($element.WGName) ($($element.GID))")
				
		foreach ($a in $element.asis)
		{
			$a_x="[ X ]"
			$b_x="[ - ]"
			
			if ($element.tobe -contains $a)
			{
				$b_x="[ X ]";$action="[ - ]"
				write-output ($form_wg_r -f $element.GID, $element.WGName,$a_x,$b_x,$action, $a,$($rid_list["$a"].Description))
			} else
		    {
				$b_x="[ - ]";$action="[DEL]"
				write-output ($form_wg_r -f $element.GID, $element.WGName,$a_x,$b_x,$action, $a,$($rid_list["$a"].Description))
				$change_ops  = [PSCustomObject]@{
                op = "remove"
                path = "/allowedRoles/$a"
              }
		  $updateOperations["$($element.GID)"]+= @($change_ops)
			}
			  
		}
		
		foreach ($b in $element.tobe)
		{
			$a_x="[ - ]"
			$b_x="[ X ]"
			
			if ($element.asis -contains $b)
			{
				#do nothing - already done in previous foreach !  $b_x="[ X ]";$action="[ - ]"
			} else
		    {
				$a_x="[ - ]";$action="[ADD]"
			 write-output ($form_wg_r -f $element.GID, $element.WGName,$a_x,$b_x,$action, $b,$($rid_list["$b"].Description))
		    	 $change_ops  = [PSCustomObject]@{
                   op = "add"
                   path = "/allowedRoles/$b"
                 }
		     $updateOperations["$($element.GID)"]+= @($change_ops)
			}
		 
		  
		}
	     #$element |convertto-json|out-host
     #  pause		 
		
	}

    if ($updateOperations.count -gt 0)
      {
	    write-Output  ($form1 -f "apply changes ?")
		write-output $linesep
		
        write-debug ($updateoperations |convertto-json	)
		$updateoperations|Out-gridview -title "Workgroup <> Roles changes" -wait
        #if (($cont=read-host ($form1 -f "apply changes? (y/n)")) -like "y")
		if (($cont=ask_continue -title "Apply changes?" -msg "apply listed changes for workgroups in $tenant ?") -like "Yes")
          {
            foreach ($i in $updateOperations.keys)
              {
                $body=$updateOperations[$i]|convertto-json		
	            if ($($updateOperations[$i].count) -eq 1 )
	              { $body="[ $body ]" }
	      		        
	            $apiUrl = "$($tenantUrl)/PlanningSpace/api/v1/workgroups/$i"	
		        # debug
				#write-output ($form1 -f "calling [$apiUrl]")
		        #write-output $body 
				# /debug
			    $line= "changing roles for group $($gid_list[$i].name)"
		        ($form_status -f  $line, "")+"`r"
                #pause
				$i_result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ( $body ) -ContentType "application/json"
              
                if ($i_result) 
                  {
				     Write-Output -NoEnumerate ($form_status -f  $line, "[DONE]")
					 Write-Log -logtext "workgroup=$($gid_list[$i].name),script=$My_name,tenant=$tenant,gid=$i,rid=$($updateOperations[$i].path),$($updateOperations[$i].op),[DONE]" -level 0
					 if ($debug){$i_result.entity|format-list}
			      } 
	            else
                  {
				     Write-Output -NoEnumerate ($form_status -f  $line, "[ERROR]")
					 Write-Log -logtext "workgroup=$($gid_list[$i].name),script=$My_name,tenant=$tenant,gid=$i,rid=$($updateOperations[$i].path),$($updateOperations[$i].op),[FAIL]" -level 2
					 #Write-Log -logtext "user=$user,script=$My_name,tenant=$tenant,uid=$($user_profile_list.id),gid=$($updateOperations[$i].path),$($updateOperations[$i].op),[FAIL]" -level 2
				  } 
				 
             }
			 write-output $linesep
           }
		   			 
      } else
	  {
	     write-Output  ($form1 -f "no changes to apply !")
		 write-output $linesep
	  }




  } # end foreach tenant


write-Output $linesep	
P2V_footer -app $My_name
Read-Host "Press Enter to close the window"
# ----- end of file -----