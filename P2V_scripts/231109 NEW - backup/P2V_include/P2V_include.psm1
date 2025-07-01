#=================================================================
#  P2V_include.psm1
#=================================================================

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
    colorcode = colorname like 'lightblue'  or HEXcode likeS. #003366"

.INPUTS
	Description of objects that can be piped to the script.

.OUTPUTS
	Description of objects that are output by the script.

.EXAMPLE
	Example of how to run the script.

.LINK
	Links to further documentation.

.NOTES
  name:   P2V_dialog_func.psm1
  ver:    1.0
  author: M.Kufner

#>

	
<# if (get-module -name "P2V_config") {if ($debug) {(Get-Module -name "*P2V*")|out-gridview -title "modules - loaded" -wait}}
else                               { import-module -name "..\P2V_config.psd1" -verbose }

if (get-module -name "P2V_PS_func") {if ($debug) {(Get-Module -name "*P2V*")|out-gridview -title "modules - loaded" -wait}}
else                               { import-module -name "..\P2V_PS_func.psd1" -verbose } #>
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
Add-Type -AssemblyName System.Windows.Forms

#=================================================================
# Variables
#=================================================================

$my_new_variable = @("dlg.WW.ADM-Services.P2V.access.production","dlg.WW.ADM-Services.P2V.access.test","dlg.WW.ADM-Services.P2V.access.update","dlg.WW.ADM-Services.P2V.access.training")



#=================================================================
# Functions
#=================================================================

Function P2V_header
{ # show header
	param (
	[string]$app="--script name--",
    [string]$path="--working directory--",
	[string]$description=""
	)
	$user=$env:UserDomain+"/"+$env:UserName
	$client=$env:ComputerName
	
	$linesep 
    $form1 -f "           \  \  \     ____  _             ______     __    _       V 1.1    /  /  / "
    $form1 -f "            \  \  \   |  _ \| | __ _ _ __ |___ \ \   / /_ _| |_   _  ___    /  /  /  "
    $form1 -f "             \  \  \  | |_) | |/ _' | '_ \  __) \ \ / / _' | | | | |/ _ \  /  /  /   "
    $form1 -f "             /  /  /  |  __/| | (_| | | | |/ __/ \ V / (_| | | |_| |  __/  \  \  \   "
    $form1 -f "            /  /  /   |_|   |_|\__,_|_| |_|_____| \_/ \__,_|_|\__,_|\___|   \  \  \  "
    $form1 -f "           /  /  /                                                           \  \  \ "
    $linesep 
    # $form2_1 -f "[$app]",(get-date -format "dd/MM/yyyy HH:mm:ss")  |out-host
    # $form2_1 -f "[$path]","[$user]"|out-host
	$form2_1 -f "[$app]","[$path]"
	$form2_1 -f "[$user] on [$client]",(get-date -format "[dd/MM/yyyy HH:mm:ss]")  
	write-log "[$user] on [$client] started [$app]"
	$linesep
	if ($description)
	{
	  $description -split "`n"| % {$form1 -f $_}
	  $linesep
	}
	
}

#-----------------------------------------------------------------
Function P2V_footer
{ # show footer
    param (
	[string]$app="--end of script--",
    [string]$path=(get-date -format "dd/MM/yyyy HH:mm:ss")  
	)
   #$linesep
   $form2_1 -f "[$app]", "$path"  
   $linesep
} # end of P2V_footer

#-----------------------------------------------------------------

Function Write-Log
{
	param (
	[string]$logtext          ,
	[int]$level			= 0
	)
	
	$logdate = get-date -format "[yyyy-MM-dd HH:mm:ss]"
	if($level -eq 0) {$severity="[INFO]"}
	if($level -eq 1) {$severity="[WARNING]"}
	if($level -eq 2) {$severity="[ERROR]"}
	
	$text= "$logdate - "+ "$severity "+ $logtext
	$text >> $logfile
}

#-----------------------------------------------------------------
Function createdir_ifnotexists 
{ # Function to create non-existing directories
  param  (
        [string]$check_path        ,
	    [bool]$verbose     = $false
	 )

      If(!(test-path $check_path))
	  {
	   $c_res=New-Item -ItemType Directory -Force -Path $check_path 
	   $msg="directory $checkpath created"
	   if ($verbose) {$form_status -f $msg,"[DONE]"|out-host}
	   Write-Log $msg
	
	  }
	
}

#-----------------------------------------------------------------
Function Delete-ExistingFile
{ # Function to delete existing files
    param(
	  [string]$file    ,
	  [bool]$verbose = $false
	)
	
    if (Test-Path $file) 
    {
        Remove-Item $file
		$msg="[$file] deleted"
	    if ($verbose) {$form_status -f $msg,"[DONE]"|out-host}
	    Write-Log $msg	
    }
}

#-----------------------------------------------------------------
Function P2V_print_object($object)   ## (OK)
{ # function to print P2V objects (e.g. user-profile)
 
	foreach ($element in $object.PSObject.Properties) 
	{
      write-output ($form2_1 -f "$($element.Name)","$($element.Value)")
    }
	
}

#-----------------------------------------------------------------
Function check_userprofile 
{ # Function to check AD userprofile and basic setup in P2V tenants
param(
  [string] $xkey ,
  [bool]   $P2Vgroups = $True,
  [bool]   $P2Vtenants = $True
   )
<#
.SYNOPSIS
	P2V_menu displays a menu based on an CSV configuration file
.DESCRIPTION
	P2V_menu displays a menu based on an CSV configuration file.
	Based on the great menu script from 
	Based on: https://github.com/weebsnore/PowerShell-Script-Menu-Gui
	just added an "EXIT" option

.PARAMETER menufile <filename>
	CSV file 
	
.PARAMETER xamldir <directory>
	CSV file 
	
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
  name:   check_userprofile.ps1 
  ver:    1.0
  author: M.Kufner

#>

#-------------------------------------------------

#  Set config variables
#$output_path = $output_path_base + "\$My_name"
P2V_header -app $MyInvocation.MyCommand -path $My_path
#$license     = @("n/a","light license","PetroVR license","heavy license","array exeeded")

#-------------------------------------------------

#----- start main part

$age=5   # refresh after $age minutes
$now=get-date
$AD_loaded=$now.addDays(-2)  # intial value very old to trigger initial load

$ad_groups=@{}
$count=0

While ($result= get_AD_user -xkey $xkey)
{
  if ($xkey){$xkey=""}
  #----- check whether xkey exists in AD and retrieve core information
  $user =  $result.SamAccountName
	  
  # $result=Get-ADUser -Filter {Name -like $user} -properties *|select Name,GivenName,Surname,UserPrincipalName,SamAccountName,EmailAddress,Department,Enabled,PasswordExpired ,LockedOut,lockoutTime, HomeDirectory 
  if(! $result) {$form_err -f "[ERROR]", " !! [$user] does not exist in Active Directory !!"   }	
  else
  { 
    
    write-output ($form1 -f  "Active Directory information for $($result.displayName)")
    write-output $linesep
	
	P2V_print_object($result)
		   
    if ($P2vgroups)
    {
      #----- check whether xkey is member of ADgroups of P2V
      $linesep
	  $form1 -f  "P2V AD group memberships for $($result.displayName)"
	  $form1 -f ""
      
      # get all AD-groups for specific useraccount
	
      #	Get-ADPrincipalGroupMembership -identity "$($result.SamAccountName)" |where name -like "*P2V*" |select name | % { $form1 -f $_.name}
      Get-ADPrincipalGroupMembership -identity "$($result.SamAccountName)"|where { $_.name -match "P2V" -or $_.name -match "PetroVR" }| % { $form1 -f $_.name }
      #$groups |format-table| out-host 
      
      if ($get_lic)  
      {
      $linesep   
         $form1 -f "license for $($result.displayName): $($license[$user_lic])"
      }
    }
	$linesep
	$form1 -f "checking PS tenant for user $($result.displayName)"
	$form1 -f ""
	$form4 -f "tenant" ,"Deactivated","AccountLocked","(ID)/Lastlogin"              		  
	#$form2_1 -f "tenant","login","islocked","isdeactivated",
	if ($P2Vtenants)
	{
        $t_list= @{}
		$tenants=select_PS_tenants -all $true
        $all_tenants =import-csv $tenantfile 
        $all_tenants |% {$t_list[$($_.tenant)]=$_}
        if (!$all_tenants) {$form_err -f "[ERROR]"," tenantfile $tenantfile does not exist"; exit }
        # $all_tenants|ft
        foreach ($ts in $tenants.keys)
		{
		  $t               = $tenants[$ts]
		  $tenant          = $t.tenant
		  $tenantURL       = "$($t.ServerURL)/$($t.tenant)"
		  $base64AuthInfo  = $t.base64AuthInfo   
	      $accessgroup     = $t.ADgroup
		  
          $API_URL         ="$tenantURL/PlanningSpace/api/v1/users" 
          $UPN             =$($result.UserPrincipalName)
		 		  
          $resp=Invoke-RestMethod -Uri $API_URL -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
          if (!$resp) {$form_err -f "[ERROR]", "cannot contact $tenant !" ;exit}
		  $resp_user=$resp|where-Object {($($_.authenticationMethod) -ne 'LOCAL' -and $_.logOnId -eq $UPN) } 
		  
		  if ($resp_user)
		  {
		    $resp_user|%{ $form4 -f "$($tenant)" ,"[$($_.isDeactivated)]/$($_.deactivatedDate)","[$($_.isAccountLocked)]/$($_.accountLockedDate)", "$($_.id)/$($_.lastLogin)"}
		  } else 
		  {
		    $form4 -f "$($tenant)","","", "[no account]"
		  }	  
		}
	}
  }
} # end while
write-output $linesep
P2V_footer -app $MyInvocation.MyCommand
}

#-----------------------------------------------------------------
Function check_P2V_user 
{ # function to check P2V user profile settings in PLanningspace
  param(
    [string]$xkey="<no user>"
  )
  #-------------------------------------------------

  #----- Set config variables
  $output_path = $output_path_base + "\$My_name"

  #-------------------------------------------------
  P2V_header -app $MyInvocation.MyCommand -path $My_path 
  createdir_ifnotexists($output_path)
  #----- start main part

  While ($result= get_AD_user -xkey $xkey)
  {
    if ($xkey){$xkey=""}
    #----- check whether xkey is member of workgroups in P2V
	$user =  $result.Name
	$UPN  =  $result.UserPrincipalName
    #[DEL] -- $dname=  "$($result.Surname) $($result.GivenName)"
	#$linesep
    $form1 -f "checking P2V Planningspace user profile for"
    $form1 -f $result.displayName
	$linesep

	$u_list_P2V=@{}
    # $all_systems = @()
   
    $tenants= select_PS_tenants
		
    foreach ($i in $tenants.keys)
    {
	  $t_sel=$tenants[$i]
      $form1 -f "--> $($t_sel.tenant) <--"
      	   
	  $authURL    ="$($t_sel.ServerURL)/identity/connect/token"
      $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t_sel.name, $t_sel.API)))
      $tenantURL  ="$($t_sel.ServerURL)/$($t_sel.tenant)"
  
    # retrieve all users incl. workgroups
      # $resp=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users?include=UserWorkgroups" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
      # if (!$resp) {$form2_1 -f "[ERROR]", "cannot contact $t_sel !" ;break}
      
	  #$resp=$resp |where {($($_.logOnId) -like $user) -or ($($_.logOnId) -like $UPN )}
	  $u_list_P2V = P2V_get_userlist ($t_sel)| where-Object {($($_.authenticationMethod) -ne 'LOCAL' -and $_.logOnId -eq $UPN) }
      #$u_list_P2V|% {$u1_list_P2V[$($_.logOnId)]=$_}
	  
      if ($u_list_P2V) 
      {
	     #P2V_print_object(($u_list_P2V|where-Object { ($($_.logonID) -like $logonID)}))#|select id,displayname,description,IsAccountLocked,isDeactivated))
          
         P2V_print_object ($u_list_P2V|
		 select id,
				displayName,
				logOnId,
				authenticationMethod,
				domain,
				accountExpirationDate,
				isDeactivated,
				isAccountLocked,
				description,
				authenticationType,
				enforcePasswordPolicy,
				enforcePasswordExpiration,
				userMustChangePassword,
				userCanChangePassword,	
				isAdministrator,
				isInAdministratorGroup,
				emailAddress,
				useADEmailAddress,
				changePassword,
				password,
				lastLogin,
				accountLockedDate,
				deactivatedDate	)
				
         $form1 -f "  workgroups: "
         foreach( $g in $u_list_P2V.userworkgroups)
         {
            $hash = @{}  
            $g | Get-Member -MemberType Properties | select -exp "Name" | % { $hash[$_] = ($g | SELECT -exp $_) }
            foreach($wg in ($hash.Values | Sort-Object -Property Name)) {$form2 -f $($wg.id), $($wg.name) }   
         }
         out-host
       } else 
       {
          $form2_1 -f "[ERROR]", "$user does not exist"
       }
       $linesep
     }
  } 
P2V_footer -app $MyInvocation.MyCommand
}

#-----------------------------------------------------------------
Function P2V_check_UPNs 
{ # function to detect differences UPN <> logonID  or department <> description for same x-key

    # local variables
	$u1_list_P2V=@{}   # userlist [LogonID]
    $u2_list_P2V=@{}   # userlist [ID]
	$u1_list_AD =@{}
	$xkey_list_P2V =@{} # userlist [xkey]  
	$UPN_list= @()
	
	# select tenant
	$tenants= select_PS_tenants
		
    foreach ($i in $tenants.keys)
    {
	  $t_sel=$tenants[$i]
      $form1 -f "--> $($t_sel.tenant) <--"
	  
	  # get all non-local accounts from P2V tenant
	  $u_list_P2V = P2V_get_userlist ($t_sel)| where-Object {($($_.authenticationMethod) -eq 'SAML2') -and !$($_.isDeactivated)}
	  
	  $form_user1 -f $u_list_P2V.count, "non-local users loaded from $tenant",""
	  
	  $u_list_P2V|% {$a =@{};
			   $a=$_;
			   $xt=$a.displayName.split("(");     # extract xkey from displayname   "first second (xkey)"
			   
#			   $xt=$a.displayName -split("("),-1 ;     # extract xkey from displayname   "first second (xkey)"
          		if ($xt.count -gt 2) {$xt=$xt[2].split(")")}
				if ($xt.count -gt 1) {$xt=$xt[1].split(")")} else{ $xt=""};
				
			   $xkey=$xt[0]
			   Add-Member -inputObject $a -Type NoteProperty -Name "xkey" -Value "$xkey";
			   $u1_list_P2V[$($a.logonID)]=$a;  
               $u2_list_P2V[$($a.id)]=$a;
			   if($xkey){$xkey_list_P2V[$($xkey)]=$a}			  	   	   
			   }
# <<start debug >>
	if ($debug)
	{	
	  $u1_list_P2V |out-gridview -title "u1_list_P2V" -wait
	  $u2_list_P2V |out-gridview -title "u2_list_P2V" -wait	
      $xkey_list_P2V|out-gridview -title "xkey_list_P2V" -wait
 	}	
# <<end debug >>

		 
	  foreach ($xkey in $($xkey_list_P2V.keys))
      {
	    $entry=@{}
	
		$UPN_local=get_AD_user -xkey $xkey
		
		$UPM_local|out-gridview -title "UPM_local" -wait
		
		#Get-ADuser -filter {Name -like $xkey} -properties *  |select UserPrincipalName,   #??? already loaded ?
		
		if ($UPN_local)
		{
		
			$entry = [PSCustomObject]@{
		       xkey=						$xkey
	           UPN=						    $UPN_local.UserPrincipalName		 # UPN from AD
			   LogonID=                     $xkey_list_P2V[$xkey].logonID			 # LogonID from P2V
			   Department=                  $UPN_local.Department				 # Department from AD
			   Description=                  $xkey_list_P2V[$xkey].description    # Description = department from P2V
			   status=					    "ACTIVE"
			   lockstatus=					"UNLOCKED"
			   action=						"CHECK"
			   lastLogin=					$xkey_list_P2V[$xkey].lastLogin
		     }
		
		    if ($xkey_list_P2V[$xkey].isDeactivated){$entry.status="INACTIVE"}
		    if ($xkey_list_P2V[$xkey].isAccountLocked){$entry.lockstatus="LOCKED"}
		    if ($entry.LogonID -eq $entry.UPN ) {$entry.action="OK"} 
		
	    	$UPN_list+=$entry
	    }
      }

	   #$UPN_list|ft
       $selected_user = @{}
       $selected_user= $UPN_list|where {$_.action -ne "OK"}|out-gridview -title "useraccounts with mismatch UPN <> LogonID"  -OutputMode multiple

       Foreach ($usel in $selected_user)
       {
	     $usel
	     #(samAccountName -like "$($usel.xkey)") -or (UserPrincipalName -like "*$($usel.LogonID))*" )
	     Get-ADuser -filter {Name -like "$($usel.xkey)"} |select samAccountName,givenname,sn,department,UserPrincipalName |fl
	   }



	}
}

#-----------------------------------------------------------------
Function P2V_check_data_access 
{ # function to read from AD groups and set the working groups accordingly
	
   param(
      [string]$xkey="<no user>",
      [bool] $selectbd=$True
    )	
    P2V_header -app $MyInvocation.MyCommand -path $My_path
	
    $PROD_compare_ADgroup="dlg.WW.ADM-Services.P2V.access.production" #default value for testing
	
	$prod_users     = @{}
	$prod_users_idx = @{}
	$AD_list        = @{}
	$AD_list_sorted = @{}
	$AD_DA_group    = @{}   # Active Directory Data Access group
	$count_total    = 0
	$count_cleaned  = 0
	#$debug          = $true
	
	
	$input_file= "\\somvat202005\pps_share\P2V_Script-setup(new)\central\config\P2V_BD_ADgroup.csv"
	write-output ($form1 -f   "loading $input_file")
	
	$AD_list= import-csv $input_file
	
	if ($debug)
	{
    	write-output ($AD_list| ft )
	    $AD_list|out-gridview -wait
	}
	
	if ($selectbd)
	{
		$AD_list = $AD_list|out-gridview -Title "select BDgroup to sync" -PassThru  
		
	}
	($AD_list| ft )   # |% {$form1 -f "$_"}
	
	# select tenant
    $tenants= select_PS_tenants
  
    foreach ($t in $tenants.keys)
    {
	  $t_sel=$tenants[$t]
      $form1 -f "--> $($t_sel.tenant) <--"
      	  
	  write-output ($tenants.Value| ft )
	  
	  
	 


	 
	}  
	

	write-output ($form1 -f   "loading productive users from $PROD_compare_ADgroup")
	$prod_users = get_AD_userlist -ad_group $PROD_compare_ADgroup -all $true
	
	$prod_users|% {$prod_users_idx[$($_.SamAccountName)]=$_}
	#$AD_list |%{ 
	
	foreach ($AD_DA_group in $AD_list)
	{
	    $members=@()
	    $members1=@()
	    $AD_list_sorted[$($AD_DA_group.ADgroup)]=$AD_DA_group
		$members1 = get_AD_userlist -ad_group $($($AD_DA_group.ADgroup)) -all $true
	    $count_total =$members1.count			
		$members1 |%{ if ($prod_users_idx.keys -contains $_.samAccountName) {$members += $($_.samAccountName)};write-progress "adding $($_.samAccountName)" }
		Add-Member -inputobject $AD_list_sorted[$($AD_DA_group.ADgroup)] -Name 'Members'     -Type NoteProperty -Value @($members)
		$count_total =$members1.count	
		$count_cleaned = $members.count
         
		write-progress "list loading done"
	    write-output  ($form3_2 -f "$($AD_DA_group.ADgroup)", "$count_total members", "$count_cleaned P2V users")
		write-progress "list loading done" -completed
		
	}
	
	
	#$ad_list| ft |out-host
	# $AD_list_sorted |out-gridview -wait
	
	foreach($adg in $ad_list_sorted.keys)
	{
		#write-output "getting members of [$adg]"|out-host
		write-output $linesep
        write-output  ($form1 -f "$adg : ")
		
		# write-output $($AD_list_sorted[$adg].Members)
		$AD_list_sorted[$adg].Members|%{ write-output ($form3_2 -f "$_", "$($prod_users_idx[$_].displayName)","$($prod_users_idx[$_].logOnId)")  }
		
 
	#    $AD_list_sorted[$adg]|out-gridview -title $adg -wait
	
	}
	
	
write-output $linesep
P2V_footer -app $MyInvocation.MyCommand
	
	
}

#-----------------------------------------------------------------
Function P2V_check_user_base_data
{ # function to sync user's base data AD <> P2V

  param(
      [string]$xkey="<no user>"
   )

  $user_compare= @{}
  # select tenant
  $tenants= select_PS_tenants
  
  foreach ($t in $tenants.keys)
  {
	  $t_sel=$tenants[$t]
      $form1 -f "--> $($t_sel.tenant) <--"
	  
      get_user_P2V_data ($xkey)
	  $user_compare.asis= get_user_P2V_data -xkey $xkey  -tenant $tenant
      
	  $user_compare.tobe= $global:usr_sel
	#<#   
	  ($form1 -f " compare base data for user $xkey")|write-output
	   ($form3_2 -f "DisplayName", $user_compare.asis.displayName,$user_compare.tobe.displayName)|write-output
	   ($form3_2 -f "LogonID", $user_compare.asis.logonID,$user_compare.tobe.UserPrincipalName)|write-output
	   ($form3_2 -f "Department", $user_compare.asis.description,$user_compare.tobe.Department)|write-output
	   ($form3_2 -f "Email", $user_compare.asis.email,$user_compare.tobe.email)|write-output
	   ($form3_2 -f "is_deactivated",$user_compare.asis.isDeactivated,$user_compare.tobe.isDeactivated) |write-output
	   ($form3_2 -f "is locked", $user_compare.asis.islocked,$user_compare.tobe.islocked)|write-output
	   ($form3_2 -f "Department", $user_compare.asis.email,$user_compare.tobe.email)|write-output
	 #   #>
	   
	   out-gridview "select changes for user $xkey" -multiple 
	   
  ## CODE IS MISSING ### incomplete

  }
}
#

#-----------------------------------------------------------------
Function P2V_sync_user
{ # function to sync user's base data AD <> P2V
  param(
      [string]$xkey="",
	  [bool]$lock=$False,
      [bool]$deactivate=$False,
      [bool]$checkOnly = $False
    )
  $u_list_AD=@{}	
  
  write-output ($form1 -f "in P2V_sync_user  xkey= [$xkey]")
  $user_selected = get_AD_user -xkey $xkey 

	
  # select tenant 
  $tenants_sel = select_PS_tenants -multiple $true -all $false
    		
	
  foreach ($ts in $tenants_sel.keys)
  {
		$t               = $tenants_sel[$ts]
        $tenant          = $t.tenant
        $tenantURL       = "$($t.ServerURL)/$($t.tenant)"
        $base64AuthInfo  = $t.base64AuthInfo   
	    $accessgroup     = $t.ADgroup

        write-progress "loading userlist from tenant <$tenant>"
		$u_list_P2V      = P2V_get_userlist($tenants_sel[$ts]) {where-Object {($($_.logOnId) -eq $user_selected.logOnId -or $($_.logOnId) -like "$($user_selected.SAMAccountName)")}}
		
		write-host $u_list_P2V
		pause
		$u_list_P2V |% {$u_list_P2V_idx[$_.logOnId]=$_ }
		
		write-progress "P2V users loaded"
		
		
		
		#$user_profile_list=get_PS_userlist $tenants[$ts] |  where-Object {($($_.logOnId) -eq $user_selected.logOnId) }
		$u_list_P2V     |% {
		write-progress "loading userlist from tenant <$tenant>" -completed
        }
  #$u_list_AD[$ga]
  
 # $u_list_AD[$ga] get_AD_user -xkey $xkey





	}# end foreach


## CODE IS MISSING ### incomplete


}

#-----------------------------------------------------------------
Function P2V_super_sync
{
<#  documentation
.SYNOPSIS
	P2V_super_sync to sync AD <> P2V on a per user base
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
  param(
    [string] $xkey = "",
    [bool]  $debug= $false
  )
  
 
  $step=0
  #----- Set config variables

  $output_path = $output_path_base + "\$My_name"
  createdir_ifnotexists($output_path)

  #----- variables definition in P2V_include
  # $spec_accounts 
 
  #----- start main part
  P2V_header -app $MyInvocation.MyCommand -path $My_path -description $description

  #------ step 1  
  # get all $adgroups
  # load AD group members in @{}
  
  $ADprofile_users = @{}         # $ADprofile_users[<AD.group>] = list of all users in AD group
  $ADuser_groups   = @{}         # $ADuser_groups[<x-key>] = list of PS-groups for this user
  $ADuser_profiles = @{}
  $User_ADgroups   = @{}         # $User_ADgroups[<x-key>] = list of "*P2V*" and "*PetroVR*" AD groups
  $all_adgroups    = @{}         # all ADgroups from config file
  $def_profiles    = @{}         # profile<> workgroup list
  $default_profile = "00DEFAULT"
  
  #$adgroupfile = $config_path + "\P2V_adgroups_devtest.csv"  # tempfile for testing
  #$all_adgroups =import-csv $adgroupfile  
  (import-csv $adgroupfile  )| % {$all_adgroups["$($_.ADgroup)"]=$_}
   <# ADGROUPFILE={
       "ADgroup":      "dlg.WW.ADM-Services.P2V.profile.Projectmanager.Classic",
        "category":    "PROFILE",
        "Lic_type":    "",
        "PSgroup":     "A08.profile.Projectmanager.Classic",
        "RESgroup":    "",
        "Description": "P2V Projectmanager Classic",
        "Comments":    "P2V Classic Projectmanager role (data entry full input tagging)",
        "Activity":    "",
        "category1":   "",
        "userclaim":   "",
        "SNOW-title":  "Projectmanager Classic",
        "SNOW-Description":  "P2V Classic Projectmanager role (data entry \u0026 \"full input\" tagging)"
    }, #>
    
  $step1=$true   # go for it !
  if ($step1)
  {
     $step++
     write-output ($form2 -f "[STEP $step]","get all AD-groups and load members")
  
     $form1 -f "loading all relevant AD groups"
     $linesep

     # load all P2V related AD groups and import users
     ForEach ($g in $all_adgroups.keys)
     {
		$i=$all_adgroups[$g]
       if ($check_group = Get-ADGroup -Identity $($i.ADgroup) )
       {
         #write-host ($form_status -f "$($i.ADgroup)","loading..")
    	 
	     $l_userlist=@()
	     $loc_userlist=Get-ADGroupMember -Identity $($i.ADgroup)|select SAMAccountName,Name
	     $loc_userlist|% {$l_userlist+=@($_.SAMAccountName)}
	  
         $ADprofile_users["$($i.ADGroup)"] =$l_userlist
	     Write-Output -NoEnumerate ($form_status -f "$($i.ADgroup)",("[{0,3}]" -f $loc_userlist.count))
	     $loc_userlist|%{if ($($i.PSGroup)) {$ADuser_profiles["$($_.SAMAccountName)"]+= @($($i.PSGroup)) }}
       } else
       {
         Write-Output -NoEnumerate ($form_status -f "$($i.ADgroup)","[n/a]")
       }
     }
	 
     $linesep 
  }
  #------ step 2
  # select users
  $step++
  Write-debug ($form2 -f "[STEP $step]","get selected user(s)")
  Write-debug $linesep 
  Write-Output -NoEnumerate ($form1 -f "select user to sync ..")
  Write-Output -NoEnumerate  $linesep 
  
  if (($xkey) -or ($cont=get_AD_user_GUI -title "P2V sync user") -eq "OK" )
  {
    $user_selected=$global:usr_sel
    #Write-Output -NoEnumerate ($linesep )
    Write-Output -NoEnumerate ($form1 -f "user selected: $($user_selected.displayname)")
    Write-Output -NoEnumerate ($form1 -f "assigned profiles")

    $u_xkey=$($user_selected.SAMAccountName)
    $u_logonID=$($user_selected.UserPrincipalName)
  
    if (! $step1)
	{
	  $ADuser_profiles["$u_xkey"]= @($default_profile)
      $local_list= @{}
	  $local_list= @(Get-ADPrincipalGroupMembership -identity "$u_xkey" |where { $_.name -like "*P2V*" -or $_.name -like "*PetroVR*" }|% { $_.name})
	 foreach ($ad_g in $local_list)
     {
	   #OLD $User_ADgroups["$u_xkey"] = @(Get-ADPrincipalGroupMembership -identity $u_xkey |where { $_.name -like "*P2V*" -or $_.name -like "*PetroVR*" }|% { $_.name})
	  
	   $User_ADgroups["$u_xkey"] += @($ad_g)
	  
	   if ($all_adgroups["$ad_g"].PSgroup) 
	      {
			 $ADuser_profiles["$u_xkey"] +=@($all_adgroups["$ad_g"].PSgroup)
	      }
	 }
	 
	 #$aduser_profiles |out-host 
  
	}
    $ADuser_profiles["$u_xkey"]|% {Write-Output -NoEnumerate ($form1 -f " *   $_")}

  $ADuser_groups["$u_xkey"] = new-object System.Collections.ArrayList
  pause
  Write-Output -NoEnumerate ($linesep)
  #------ step 3
  # select tenant(s)
  $step=3
  Write-debug ($form2 -f "[STEP $step]","get selected tenant(s)")
  Write-debug $linesep 
  Write-Output -NoEnumerate ($form1 -f "select tenant(s) to sync :")
  Write-Output -NoEnumerate $linesep
  $tenants=select_PS_tenants -multiple $true -all $false
  #$tenants.keys|% {P2V_print_object $tenants[$_] }
  Write-Output -NoEnumerate ($form1 -f "tenants selected:")
  $tenants.keys|% { Write-Output -NoEnumerate ($form1 -f " > $($tenants[$_].tenant)" )}

  Write-Output -NoEnumerate ($linesep  )
  
  #------ step 4
  # load all profile -definitions
  $step++
  $step++
  Write-debug ($form2 -f "[STEP $step]","translate profiles -> workgroups")
  Write-debug $linesep
  Write-Output -NoEnumerate ($form1 -f "translate profiles -> workgroups" )
  $def_profiles= get_profiles -debug $false

  Write-Output -NoEnumerate ($linesep)

  foreach ($p in $ADuser_profiles["$u_xkey"])
  {
    Write-Output -NoEnumerate ($form_err -f "P:","[$p]")
   
    foreach ($g in $def_profiles["$p"])
    {
      write-debug ($form1 -f "G[$g]:")
      if ($ADuser_groups["$u_xkey"] -notcontains $g)
      {
	     $ADuser_groups["$u_xkey"].Add("$g")|out-null
	     write-debug ($form3 -f $u_xkey,"$g","[ADD]")
	  }
	  else
	  {
         write-debug ($form1 -f "skip double $g")
      }	   
    }
  }
  $linesep
  #if ($debug) {pause}
  #------ step 5
  write-debug "step 5:"
  
  # write-debug  $ADuser_groups["$u_xkey"].GetType().FullName 
  # check group dependencies (data.country.eco,..)
  #$ADuser_groups["$u_xkey"]|convertto-json |out-host

  $step++
  Write-Output -NoEnumerate ($form2 -f "[STEP $step]","check and correct user/workgroup assignments")
  Write-Output -NoEnumerate ($linesep)
  Write-Output -NoEnumerate ($form1 -f "--> check_datagroup_dependencies")
  $ADuser_groups["$u_xkey"]= [System.Collections.ArrayList] (check_datagroup_dependencies -grouplist $ADuser_groups["$u_xkey"] -debug $false)
  #Write-debug  $ADuser_groups["$u_xkey"].GetType().FullName 

  # check BD permissions (allow - deny)
  Write-Output -NoEnumerate ($form1 -f "--> check_BD_dependencies")
  $ADuser_groups["$u_xkey"] = [System.Collections.ArrayList] ( check_BD_dependencies -login $u_logonID -grouplist $ADuser_groups["$u_xkey"] -debug $false)
  #Write-debug  $ADuser_groups["$u_xkey"].GetType().FullName 

  # check licences groups (heavy - light)
  Write-Output -NoEnumerate ($form1 -f "--> check_license_dependencies")
  $ADuser_groups["$u_xkey"] = [System.Collections.ArrayList] (check_license_dependencies -grouplist $ADuser_groups["$u_xkey"] -debug $false )
  #Write-debug  $ADuser_groups["$u_xkey"].GetType().FullName 

  # check template permissions (fullaccess - readonly - deny)
  Write-Output -NoEnumerate ($form1 -f "--> check_template_dependencies")
  $ADuser_groups["$u_xkey"] = [System.Collections.ArrayList] ( check_template_dependencies -grouplist $ADuser_groups["$u_xkey"] -debug $false )
  #Write-debug  $ADuser_groups["$u_xkey"].GetType().FullName 

  #Write-Debug $linesep
  #$ADuser_groups["$u_xkey"] |% {Write-host ($form1 -f "$_")}
  #if ($debug) {pause}
  
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
	
    $user_profile_asis = @{}
    $user_profile_tobe = @{}
  
    $change_ops= @{}
    $updateOperations= @{}
    $group_list= @{}
    $g_list= @{}
  
    #$user_profile_list=get_PS_userlist $tenants[$ts] |  where-Object {($($_.logOnId) -eq $user_selected.logOnId) }
	$user_profile_list=P2V_get_userlist -tenant $t |  where-Object {($($_.logOnId) -eq $user_selected.logOnId) }
    $U_G_list= @()
    $group_list=get_PS_grouplist $tenants[$ts]|select id,name,description,comments,externalGroup
    $group_list|% {$g_list[$($_.name)]=$_ }
	
	#------------- check if user is entitled to access the systemaccess
	Write-Output -NoEnumerate ($form1 -f "check if user is entitled to access $tenant")
	Write-Output -NoEnumerate $emptyline
	
	# if user in Tenant.AD.accesslist & user does not exist in P2v -> ask & ADD user
    
	# if user in Tenant.AD.accesslist & user deactivated in P2V -> ask & activate user
		
	# if user in P2v but not in Tenant.AD.Accesslist  -> ask & deactivate user
	
	# if user not in P2V and not in Tenant.AD.Accesslist  -> warning msg & skip
	
	# if user deactivated in P2v and not in Tenant.AD.Accesslist  -> ask and delete groups (deactviate)
	
	# if user in Tenant.AD.accesslist
 
    	
	# OLD:   if ($ADprofile_users["$accessgroup"] -contains $u_xkey)
	if ($User_ADgroups["$u_xkey"] -contains $accessgroup)
	  {
	#     if user not in tenant ->  ask & add
	    if (!$user_profile_list)
		  {  # add user
		     write-output ($form_1 -f "$($user_selected.Displayname) does not exist in $tenant") 
			 $to_be = [PSCustomObject]@{
		        logOnId              = $user_selected.logOnId
                displayName 		 = $user_selected.displayName
                description 		 = $user_selected.Department
                isDeactivated 		 = $False
                isAccountLocked 	 = $False
                authenticationMethod = "SAML2"
				useADEmailAddress    = $False
				emailAddress         = $user_selected.EmailAddress
            }
			if ($debug){$to_be|format-list}
			#if (($cont=read-host ($form1 -f "add user $($user_selected.displayName) to $tenant ? (y/n)")) -like "y")
			if (($cont=ask_continue -title "Add user?" -msg "add user $($user_selected.displayName) to $tenant ?") -like "Yes")
			{
	            $rc= add_PS_user -tenant $t -user_profile $to_be 
				if (!$rc){write-warning "error in adding user"}
			}
			# reload user-profile
			
			 $user_profile_list=get_PS_userlist $tenants[$ts] |  where-Object {($($_.logOnId) -eq $user_selected.logOnId) }
		  }
	#     if user deactivated   ->  ask & activate
	    if ($user_profile_list.isdeactivated)
		  {
		     Write-Output -NoEnumerate ($form_status -f "$($user_selected.Displayname) is deactivated in $tenant","[ACTIVATE]")  
			 #if (($cont=read-host ($form1 -f "activate user $($user_selected.displayName) in $tenant ? (y/n)")) -like "y")
			 if (($cont=ask_continue -title "Activate user?" -msg "activate user $($user_selected.displayName) in $tenant ?") -like "Yes")
			{
			  activate_PS_user -tenant $t -User_Id $user_profile_list.id
			}
			 
		  }
		else
	      {
		     Write-Output -NoEnumerate ($form_status -f "$($user_selected.Displayname) is activated in $tenant","[CHECK]")  
		  }
	  } 
	else
	  {
	# else (not in Tenant.AD.accesslist)
	#     if user in P2V        
	     if ($user_profile_list)
		  {
		    if ($user_profile_list.isdeactivated)
		      {
			    Write-Output -NoEnumerate ($form_status -f "$($user_selected.Displayname) already is deactivated in $tenant - delete groups","[DEACTIVATE]")  
			  } 
	#         if user is deactivated ->  ask & activate & deactivate (delete groups)
              else 
			  {
			    Write-Output -NoEnumerate ($form_status -f "$($user_selected.Displayname) already is deactivated in $tenant - delete groups","[DEACTIVATE]")  
			    #if (($cont=read-host ($form1 -f "deactivate user $($user_selected.displayName) in $tenant ? (y/n)")) -like "y")
		        if (($cont=ask_continue -title "Deactivate user?" -msg "deactivate user $($user_selected.displayName) in $tenant ?") -like "Yes")
			{
			  deactivate_PS_user -tenant $t -User_Id $user_profile_list.id
			}
			  } 
	#         else
	#            ->  ask  & deactivate (delete groups)
	      }
		 else
	      {
		    Write-Output -NoEnumerate ($form_status -f "$($user_selected.Displayname)-no AD, no P2V","[SKIP]")
		  }

	#     else
    #        ->  relax and skip  (nothing to do)	
	    
	  }

    foreach ($gs in  $($user_profile_list.userWorkgroups))
    {
 	  $hash = @{}            
      $gs | Get-Member -MemberType Properties | select -exp "Name" | % { $hash[$_] = ($gs | SELECT -exp $_) }
	  foreach($wg in ($hash.Values | Sort-Object -Property Name))
      {
	    if ($($wg.name) -notlike "Everyone")
	    {
          $user_profile_asis["$u_xkey"]+=@($($wg.name))
		  $U_G_list+=$($wg.name)
	    }
	  }
    }
    #[System.Collections.ArrayList]$templist=$U_G_list
    Write-debug "ADuser_groups"
    $ADuser_groups["$u_xkey"]|% { write-debug $_.tostring()}
    
    $user_profile_list |Add-Member  -MemberType NoteProperty  -Name asis -value $U_G_list
    $user_profile_list.asis = $U_G_list
    $user_profile_list |Add-Member  -MemberType NoteProperty  -Name tobe -Value $ADuser_groups["$u_xkey"] 
    $user_profile_list.tobe = $ADuser_groups["$u_xkey"]
    #$user_profile_list|select LogonID, asis, tobe |format-table
  
    Write-Output -NoEnumerate ($form2 -f $ts,$user_profile_list.LogonID)
	Write-Output -NoEnumerate ($emptyline)
    Write-Output -NoEnumerate ($form3_2 -f "AS-IS","TO-BE","ACTION")
    Write-Output -NoEnumerate ($linesep)
	
    $user_profile_list.asis|% { 
      if ($user_profile_list.tobe -contains $_)
   	    { 
	      Write-Output -NoEnumerate ($form3_2 -f $_,$_,"[ - ]")
	    } 
	  else
	    { 
	      Write-Output -NoEnumerate ($form3_2 -f $_,"-","[DEL]")
	  	  $gid=$g_list["$_"].id
		  $change_ops  = [PSCustomObject]@{
           op = "remove"
           path = "/userworkgroups/$gid"
           value = ""
		   }
		  $updateOperations["$($user_profile_list.id)"]+= @($change_ops)	
	    } 
    }
    $user_profile_list.tobe|% { 
      if ($user_profile_list.asis -notcontains $_) 
	    {  
	      Write-Output -NoEnumerate ($form3_2 -f "-",$_,"[ADD]")
		  $gid=$g_list["$_"].id
		  $change_ops  = [PSCustomObject]@{
              op = "add"
              path = "/userworkgroups/$gid"
              value = ""
			  }
		  $updateOperations["$($user_profile_list.id)"]+= @($change_ops)
	    } 
	  else
	    {  write-debug ($form3_2 -f $_,$_,"[SKIP]")}
    }
 
    write-Output $linesep
    write-debug ($form1 -f "json to patch")
    write-debug $linesep
 
    if ($updateOperations.count -gt 0)
      {
	    write-Output  ($form1 -f "apply changes ?")
		write-output $linesep
		
        write-debug ($updateoperations |convertto-json	)
        #if (($cont=read-host ($form1 -f "apply changes? (y/n)")) -like "y")
		if (($cont=ask_continue -title "Apply changes?" -msg "apply listed changes for $($user_selected.Displayname) in $tenant ?") -like "Yes")
          {
            foreach ($i in $updateOperations.keys)
              {
                $body=$updateOperations[$i]|convertto-json		
	            if ($($updateOperations[$i].count) -eq 1 )
	              { $body="[ $body ]" }
	      		        
	            $apiUrl = "$($tenantUrl)/PlanningSpace/api/v1/users/$($user_profile_list.id)"	
		        write-debug ($form1 -f "calling [$apiUrl]")
		        write-debug $body 
			    $line= "changing groups for user $($user_profile_list.displayname)"
		        ($form_status -f  $line, "")+"`r"
                $i_result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ( $body ) -ContentType "application/json"
              
                if ($i_result) 
                  {
				     Write-Output -NoEnumerate ($form_status -f  $line, "[DONE]")
					 if ($debug){$i_result.entity|format-list}
			      } 
	            else
                  {
				     Write-Output -NoEnumerate ($form_status -f  $line, "[ERROR]")
				  } 
				 
             }
			 write-output $linesep
           }
		   			 
      } else
	  {
	     write-Output  ($form1 -f "no changes to apply !")
		 write-output $linesep
	  }
 
    #if ($debug) {pause}
    #       write logfile
  } # end foreach tenant 
 }
 
P2V_footer -app $MyInvocation.MyCommand
}

Function P2V_sync_tenant
{ # function to sync tenant access (deactivates P2V SAML accounts without proper ADgroup membership  and creates missing accounts in P2V , sync Metadata of users, all selections editable)
 
  #-- select users 
  $u1_list_vendor=@{}
  $P2V_userlist=@{}
  $AD_userlist=@{}
 
  P2V_header -app $My_name -path $My_path 
  
  # select tenant
  $tenants= select_PS_tenants

  foreach ($t in $tenants.keys)
  {
		 
	 $t_sel=$tenants[$t]
     write-output ($form1 -f "--> $($t_sel.tenant) <--")
      
	 if ($AD_userlist.keys -contains  $($t_sel.ADgroup)) 
	   { write-output ($form1 -f "$($t_sel.ADgroup) already loaded - skipping")}
	 else   
	   {   
	      $u_list_AD= @{}
	      $u_list_AD = get_AD_userlist -ad_group $($t_sel.ADgroup)
		  if (!$u_list_AD) {write-output ($form_err -f "[ERROR]", "cannot load $($t_sel.ADgroup) !") ; return $false}
          $AD_userlist[$($t_sel.ADgroup)] = $u_list_AD 
	   }
	  
	 if ($P2V_userlist.keys -contains $($t_sel.tenant)) 
	   { write-output ($form1 -f "$($t_sel.tenant) already loaded - skipping")}
	 else   
	   {   
	      $u_list_P2V= @{}
	      $u_list_P2V = P2V_get_userlist -tenant $t_sel
		  $P2V_userlist[$($t_sel.tenant)] = $u_list_P2V | where-Object { $_.authenticationMethod -ne "LOCAL" }   
	   }

     write-output ($form3_2 -f "AD-group: $($AD_userlist[$($t_sel.ADgroup)].count)","P2V: $($P2V_userlist[$($t_sel.tenant)].count)", "users loaded")
	 
    #--- check differences
	
	$acount=0
	$ccount=0
	$dcount=0
	$scount=0
	$add_ops=@()
	$del_ops=@()
	$change_ops=@()
	$updateOperations = @{}
	$deleteOperations = @{}
	
    # check cases:
	# 1.   User exists in AD but not yet in P2V -> create P2V account or delete AD membership (check manually)
	# 2.   User exists in P2V but not in  AD    -> deactivate 
    # 3.   User exists in AD  and in P2V        -> update metadata
	
	
	## CODE IS MISSING ### incomplete
	
	
	
	
	
	
	
	$AD_userlist[$($t_sel.tenant)] |out-gridview "P2V userlist" -wait
	
	$P2V_userlist[$($t_sel.tenant)] |out-gridview "P2V userlist" -wait
	
	
	
	
	
	
	
	
	
	
	
	
	


	
  }
  P2V_footer -app $My_name -path $My_path 
}



Function P2V_lock_inactive_users
{
   param(
   [string]$tenant="",
   [int]$max_days_lock=365,      # 12 months - phase 1 -> lock
   [int]$max_days_deactivate=585,      # 18 months  6*30 + 365 =585   phase 2 -> deactivate
   [bool]$lock=$False,
   [bool]$deactivate=$False,
   [bool]$checkOnly = $False
)
#-------------------------------------------------
$My_name=$($MyInvocation.MyCommand.Name)
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
$user=$env:UserDomain+"/"+$env:UserName
if (!$workdir) {$workdir=$My_Path}
. "$workdir/P2V_include.ps1"

#----- Set config variables
$output_path = $output_path_base + "\$My_name"
$u_w_file= $output_path + "\Myuserworkgroup.csv"

#[ERROR]: missing argument(s)  
#
#correct usage:  
#$My_name  -tenant ttt  [-lock l] [-deactivate d] [-checkonly c]#
#
#    ttt ... existing tenant
#  optional
#       l ... TRUE to lock  / FALSE to unlock 
#       d ... TRUE to deactivate / FALSE to activate
#       c ... TRUE : only check status / FALSE change settings (default:TRUE)
#"

#----- start main part
P2V_header -app $My_name -path $My_path 

#----- user / profiles to keep even without login

$UserProfilesToSkip = @("A02.profile.PetroVR",
						"A03.profile.CAPDAT",
						"PetroVR"
					   )


$tenants=select_PS_tenants -multiple $true -all $false
Write-Output -NoEnumerate ($form1 -f "tenants selected:")
$tenants.keys|% { Write-Output -NoEnumerate ($form1 -f " > $($tenants[$_].tenant)" )}
Write-Output -NoEnumerate ($linesep  )


#----- check whether xkey is member of workgroups in P2V

  
foreach ($ts in $tenants.keys)
{
	$t               = $tenants[$ts]
	$tenant          = $t.tenant
	$tenantURL       = "$($t.ServerURL)/$($t.tenant)"
	$base64AuthInfo  = $t.base64AuthInfo   
	$accessgroup     = $t.ADgroup

    $form1 -f "--> $tenant <--"
    Write-Output -NoEnumerate ($form1 -f "lock all inactive users in  [$tenant]")
    $linesep

	$UsersFromTenantList        = @{}
	$UsersFromTenantListNever   = @{}
	$UsersFromTenantListMaxDays = @{}
	$UsersFromTenant            = @{}
	# $max_days=365 -> as parameter
	
	$UsersFromTenantList= get_PS_userlist $t 
	$UsersFromTenantList|%{$UsersFromTenant[$($_.LogonID)]=$_}
	$UsersFromTenantList=$UsersFromTenantList|Where { ($_.authenticationMethod -ne "LOCAL") }   #skip local users
	
    Write-Output -NoEnumerate ($form1 -f "LOCAL users are skipped")
	$UsersFromTenantListNever=$UsersFromTenantList| select id, displayName,logOnId,description,isAccountLocked,isDeactivated,lastlogin |where {(! $($_.lastlogin)) -and ( ! $($_.isDeactivated))}  # |out-gridview -Title "NEVER logged in"
	
	$UsersFromTenantListMaxDays=($UsersFromTenantList|select id, displayName,logOnId,description,isAccountLocked,isDeactivated,lastlogin |where {( $($_.lastlogin)) -and ( ! $($_.isDeactivated)) -and ((New-Timespan -start (get-date -date "$($_.lastlogin)") -end (get-date -uformat "%Y-%m-%dT%TZ")).days -gt $max_days_lock)}) 
	# ,(New-Timespan -start (get-date -date $($_.lastlogin)) -end (get-date))
    #(New-Timespan -start (get-date -date "lastlogin") -end 
	
	write-output $linesep
	
	write-output ($form_status -f " Active and NEVER logged in: ",$UsersFromTenantListNever.count)
		   
    $updateOperations = @{}
	$updateUserOperations =@()
    # retrieve all users incl. workgroups


	 $UsersFromTenantListNever =  $UsersFromTenantListNever |out-gridview -Title "ACTIVE and NEVER logged in - select user(s) to deactivate" -OutputMode multiple
     write-output ($form_status -f "users selected for de-activation: ",$UsersFromTenantListNever.count)
	 
	 if (($cont=read-host ($form1 -f "deactivate $($UsersFromTenantListNever.count) users? (y/n)")) -like "y")	
	 {
		 foreach ($u in $UsersFromTenantListNever)
		 {
			$updateUserOperations =@()
			$updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/isDeactivated"
                    value = $true
            }
			$updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/description"
			         value = "[deactivated due to inactivity] - $($u.description)"
            }
			# 
			 
		    if ($updateUserOperations.Count -gt 0)
            {
                $updateOperations[$u.id.ToString()] = $updateUserOperations                
            } 
			
			$result = Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users/bulk" -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ($updateOperations|ConvertTo-Json) -ContentType "application/json"
			
			if ($result) {$status="[DONE]"} else	{$status="[FAIL]"}
			
			write-output  ($form_status -f "     deactivating $($u.displayName)[$($u.logOnId)]",$status)
			Write-Log -logtext "user=$user,script=$My_name,tenant=$tenant,uid=$($u.id)/$($u.logOnId)/$($u.displayName) deactivated as user never logged in, $status" -level 0
						
		 }
		
		 
	 }
	 
	write-output $linesep
    write-output ($form_status -f " Active and not  logged in for $max_days days:",$UsersFromTenantListMaxDays.count)

    $UsersFromTenantListMaxDays=$UsersFromTenantListMaxDays |out-gridview -Title "ACTIVE and not logged in for $max_days days - select user(s) to lock" -OutputMode multiple
	write-output ($form_status -f "users selected to lock",$UsersFromTenantListMaxDays.count)
      
	if (($cont=read-host ($form1 -f "lock $($UsersFromTenantListMaxDays.count) users? (y/n)")) -like "y")	
	 {
		 foreach ($u in $UsersFromTenantListMaxDays)
		 {
			$updateUserOperations =@()
			$updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/isAccountLocked"
                    value = $true
            }
			$updateUserOperations += [PSCustomObject]@{
                    op = "replace"
                    path = "/description"
			        value = "[locked due to inactivity $max_days] - $($u.description)"
            }
			# 
			 
		    if ($updateUserOperations.Count -gt 0)
            {
                $updateOperations[$u.id.ToString()] = $updateUserOperations                
            } 
			
			$result = Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users/bulk" -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ($updateOperations|ConvertTo-Json) -ContentType "application/json"
			
			if ($result) {$status="[DONE]"} else	{$status="[FAIL]"}
			
			write-output  ($form_status -f "     locking $($u.displayName)[$($u.logOnId)]",$status)
			Write-Log -logtext "user=$user,script=$My_name,tenant=$tenant,uid=$($u.id)/$($u.logOnId)/$($u.displayName) locked as user has not logged in for $max_days days, $status" -level 0
						
		 }
			 
	 }
}
	 write-output $linesep
     P2V_footer -app $MyInvocation.MyCommand
    
	
	
	
}



#=================================================================
# Exports
#=================================================================

Export-ModuleMember -Variable workdir
Export-ModuleMember -Function * -Alias *

