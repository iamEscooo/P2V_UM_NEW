#-----------------------------------------
# P2V_rename_workgroups
#-----------------------------------------
param(
    # [string]$tenantUrl = "https://ips-test.ww.omv.com/P2V_TRAINING",
    [string]$workingDir = "\\somvat202005\PPS_share\P2V_UM_data\",
    [bool]$analyzeOnly = $True
)
<#  documentation
.SYNOPSIS
	P2V_rename_workgroups to read list of <old name> <new name> records and apply changes to selected tenant
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
	none

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
  
#>

#-------------------------------------------------
$My_name=$($MyInvocation.MyCommand.Name)
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir\P2V_include.ps1"
. "$workdir\P2V_forms.ps1"
$user=$env:UserDomain+"/"+$env:UserName 

#----- Set config variables

$output_path = $output_path_base + "\AUCERNAusermgmt"
$u_w_file= $output_path + "\Myuserworkgroup.csv"


#------------------ START OF SCRIPT LOGIC -----------------------------

# Log summary of passed parameters
cls

P2V_header -app $My_name -path $My_Path

Write-Output "This script will only rename workgroups and update description and comments"
Write-Output "Please note that this script will only warn on workgroups and users that can possibly be deleted. Please login to PlanningSpace application to perform the actual deletion."
Write-Output -NoEnumerate ($linesep)
#  step 1
#  read workgroup-rename file 
# expected format:   <WGname_ASIS>;<WGname_TOBE>
# not now ;<Description_TOBE>,<Comments_TOBE>

do{
Write-Output "|> select change_workgroup_names file:  "
$change_workgroupsFile = Get-FileName ($workingDir)
Write-Output "[$change_workgroupsFile]"
}until(($cont=read-host ("continue with selected file (y/n)")) -like "y")

# Load CSV files
$form1 -f "Loading from input CSV file..."

$changesFromCsv=@{}
$changesFromCsv=Import-Csv $change_workgroupsFile 

# DEBUG: if ($analyzeOnly) { $changesFromCsv|ft ;pause}

$tenants=select_PS_tenants -multiple $true -all $false

# DEBUG: Write-Output $chg_WG
$tenants.keys|% { Write-Output -NoEnumerate ($form1 -f " > $($tenants[$_].tenant)" )}

Write-Output -NoEnumerate ($linesep  )
$group_list= @{}
$g_list= @{}
$gid_list= @{}
$change_ops= @{}
$updateOperations= @{}


foreach ($ts in $tenants.keys)
  {
    $t               = $tenants[$ts]
    $tenant          = $t.tenant
    $tenantURL       = "$($t.ServerURL)/$($t.tenant)"
    $base64AuthInfo  = $t.base64AuthInfo   
	$accessgroup     = $t.ADgroup
    # $PS_users= get_PS_userlist -tenant $t
    
	# $ADgroup_users[ADgroup]= userlist @()
    #load all "profiles" to user
    #-- #   read profiles
    #Write-Output -NoEnumerate ($linesep)
	Write-Output -NoEnumerate ($form1 -f ">> checking tenant [$tenant] <<")
	Write-Output -NoEnumerate ($linesep)
	
	$group_list=get_PS_grouplist $tenants[$ts]|select id,name,description,comments,externalGroup
    $group_list|% {$g_list[$($_.name)]=$_ ; $gid_list["$($_.id)"]=$_ }

# DEBUG: 	if ($analyzeOnly) { $g_list|ft ;pause}
	
	Write-Output -NoEnumerate ($form_logs -f "ID","P2V WGname","WGname ASIS","WGName TOBE","Action")
	
	foreach ($chg_WG in $changesFromCsv)	
	{
		$asis=0
		$tobe=0
	   
		if($chg_WG.WGname_ASIS -ne $chg_WG.WGname_TOBE)
		{

			if ($chg_WG.WGname_ASIS -and ($g_list.keys -contains $chg_WG.WGname_ASIS)) {$asis=$g_list[$chg_WG.WGname_ASIS].id}

			if ($chg_WG.WGname_TOBE -and ($g_list.keys -contains $chg_WG.WGname_TOBE)) {$tobe=$g_list[$chg_WG.WGname_TOBE].id}
		
			
			if ($asis -and $tobe)
			{ # error - both names are existing
				Write-Output -NoEnumerate ($form_logs -f "[-]","both are existing", "$($g_list[$chg_WG.WGname_ASIS])/$asis", "$($g_list[$chg_WG.WGname_TOBE])/$tobe","[ SKIP ]")
			}else
			{
				if ($asis)
				{ #only old name exists
					Write-Output -NoEnumerate ($form_logs -f "[$asis]", $($g_list[$chg_WG.WGname_ASIS].name), $chg_WG.WGname_ASIS,$chg_WG.WGname_TOBE,"[CHANGE]")
					if (!$updateOperations.ContainsKey("$asis"))
                        {
                            $updateOperations["$asis"] = @()
                        }
                    $updateOperations["$asis"] += [PSCustomObject]@{
							op = "replace"
                            path = "name"
                            value = "$($chg_WG.WGname_TOBE)"
                        }
				} else
				{ 
					if ($tobe)
					{	
						Write-Output -NoEnumerate ($form_logs -f "[$tobe]", $($g_list[$chg_WG.WGname_ASIS].name), $chg_WG.WGname_ASIS,$chg_WG.WGname_TOBE,"[ SKIP ]")
					}else
					{ # NOT $asis and NOT  $tobe
						Write-Output -NoEnumerate ($form_logs -f "[*ERROR]", "none found", $chg_WG.WGname_ASIS,$chg_WG.WGname_TOBE,"[ SKIP ]")
					}
				}			
			}
		} else
        {
			# Write-Output -NoEnumerate ($form_chlogs -f "[*ERROR*]","both are equal", $($g_list[$chg_WG.WGname_ASIS]).name, $($g_list[$chg_WG.WGname_TOBE].name),"skipping entry")
		}
		
		    #    $updateOperations["$($user_profile_list.id)"]+= @($change_ops)	
			
	}
    if ($updateOperations.count -gt 0)
    {
	     #write-Output  ($form1 -f "apply $($updateOperations.count) changes ?")
	   	 write-output $linesep
	
	     write-debug ($updateOperations|convertto-Json)
		 
		if (($cont=ask_continue -title "Apply changes?" -msg "apply $($updateOperations.count) changes ?") -like "Yes")
        {
            foreach ($i in $updateOperations.keys)
            {  
				$body=$updateOperations[$i]|convertto-json		
	            if ($($updateOperations[$i].count) -eq 1 )
	            { $body="[ $body ]" }
	      		        
	            $apiUrl = "$($tenantUrl)/PlanningSpace/api/v1/workgroups/$i"	
		        write-debug ($form1 -f "calling [$apiUrl]")
		        write-debug $body 
				
			    $line= "tenant=$tenant,gid=$i,$($gid_list[$i.tostring()].name) renaming to $($updateOperations[$i].value)"
		        # ($form_status -f  $line, "")+"`r"
                $i_result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ( $body ) -ContentType "application/json"
			    
                if ($i_result) 
                {
				     Write-Output -NoEnumerate ($form_status -f  $line, "[DONE]")
					 Write-Log -logtext "user=$user,script=$My_name,tenant=$tenant,gid=$i,$($gid_list[$i.tostring()].name) renamed to $($updateOperations[$i].value),[DONE]" -level 0
					 if ($debug){$i_result.entity|format-list}
			    } 
	            else
                {
				     Write-Output -NoEnumerate ($form_status -f  $line, "[ERROR]")
					 Write-Log  -logtext "user=$user,script=$My_name,tenant=$tenant,gid=$i,$($gid_list[$i.tostring()].name) renamed to $($updateOperations[$i].value),[FAIL]" -level 2
				} 
			}
		}
	}	
  }
write-Output $linesep	
P2V_footer -app $My_name
Read-Host "Press Enter to close the window"
# ----- end of file -----