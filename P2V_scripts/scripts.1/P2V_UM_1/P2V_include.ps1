#=======================
#  P2V_include.ps1
#  V 0.5
#  
#  general P2V functions for usermgmt
#
#  Martin Kufner
#=======================
#  1. P2V_layout
#  2. P2V_header
#  3. P2V_footer  
#  4. P2V_Show-Menu
#
#-------------------------------------------------------
#  central layout settings
#-- check if already called (ne)
if ($called) {exit}
$called=$True

Function P2V_layout() ## DELETE   ?!?!!
{
  	$r=[System.Windows.MessageBox]::Show("P2V_layout called !!","P2V_layout") 

  return $True
}

Function P2V_header
{ # show header
	param (
	[string]$app="--script name--",
    [string]$path="--working directory--"
	)
	$user=$env:UserDomain+"/"+$env:UserName
	$client=$env:ComputerName
	
	$linesep |out-host
    $form1 -f " \  \  \     ____  _             ______     __    _       V 1.1    /  /  / "
    $form1 -f "  \  \  \   |  _ \| | __ _ _ __ |___ \ \   / /_ _| |_   _  ___    /  /  /  "
    $form1 -f "   \  \  \  | |_) | |/ _' | '_ \  __) \ \ / / _' | | | | |/ _ \  /  /  /   "
    $form1 -f "   /  /  /  |  __/| | (_| | | | |/ __/ \ V / (_| | | |_| |  __/  \  \  \   "
    $form1 -f "  /  /  /   |_|   |_|\__,_|_| |_|_____| \_/ \__,_|_|\__,_|\___|   \  \  \  "
    $form1 -f " /  /  /                                                           \  \  \ "
    $linesep |out-host
    # $form2_1 -f "[$app]",(get-date -format "dd/MM/yyyy HH:mm:ss")  |out-host
    # $form2_1 -f "[$path]","[$user]"|out-host
	$form2_1 -f "[$app]","[$path]"|out-host
	$form2_1 -f "[$user] on [$client]",(get-date -format "[dd/MM/yyyy HH:mm:ss]")  |out-host    
	write-log "[$user] on [$client] started [$app]"
	$linesep|out-host
}

Function P2V_footer
{ # show footer
    param (
	[string]$app="--end of script--",
    [string]$path=(get-date -format "dd/MM/yyyy HH:mm:ss")  
	)
   $linesep|out-host
   $form2_1 -f "[$app]$form", "$path"  |out-host
   $linesep|out-host
} # end of P2V_footer

Function P2V_Show-Menu              #( -> GUI???)
{ # show_menu
     param (
           [string]$Title = 'Usermanagement',
	       [array]$menu= @()
	     )
             
     $form2 -f "",$Title |out-host
     $linesep|out-host
                
     foreach ($i in 1 ..$menu.count) {$form2 -f $i,$menu[$i-1]|out-host}
	 
     $form2 -f "",""|out-host
     $form2 -f "0","exit"|out-host
     $form2 -f "",""|out-host
     $linesep|out-host
	 out-host
}

Function Delete-ExistingFile([string]$file_to_delete,[bool]$verbose=$false)
{ # Function to delete existing files
    if (Test-Path $file_to_delete) 
    {
        Remove-Item $file_to_delete
		$msg="[$file_to_delete] deleted"
	    if ($verbose) {$form_status -f $msg,"[DONE]"|out-host}
	    Write-Log $msg
    }
}

Function createdir_ifnotexists ([string]$check_path,[bool]$verbose=$false)
{ # Function to create non-existing directories
      If(!(test-path $check_path))
	  {
	   $c_res=New-Item -ItemType Directory -Force -Path $check_path 
	   $msg="directory $checkpath created"
	   if ($verbose) {$form_status -f $msg,"[DONE]"|out-host}
	   Write-Log $msg
	  }
}

Function P2V_print_object($uprofile)   ## (OK)
{ # function to print P2V objects (e.g. user-profile)
 
	foreach ($element in $uprofile.PSObject.Properties) 
	{
      $form2_1 -f "$($element.Name)","$($element.Value)"
    }
	$linesep
	out-host
}

Function P2V_get_tenant($tenantfile)
{ # function to select tenant (commandline - ascii)
  
  $all_systems =import-csv $tenantfile 
  if (!$all_systems) {$form_err -f "[ERROR]"," tenantfile $tenantfile does not exist"; exit }
  
  $t_list=@()
  
  foreach ($a in $all_systems){ $t_list+=$a.tenant }
  $linesep |out-host
  P2V_Show-Menu -Title "select tenant" -menu $t_list
  out-host
  do {
    
    $inp_l=read-host ($form1 -f ">>> Please select a tenant")	
    switch ($inp_l)
    {
	 '0'	  {return ""}
	 default  { 
	           if ($inp_l -in 1..$t_list.count )
	            {$t_sel=$t_list[$inp_l-1]}
	           else
		        {"wrong input" }
	          }
    }
  }until ($inp_l -in 1..$t_list.count )
  
  $t_resp=$all_systems |where {($($_.tenant) -eq $t_sel)}
  $linesep|out-host
  $form1 -f "[$($t_resp.tenant)] selected"|out-host
  $linesep|out-host
  #return [string]$t_sel
  return $t_resp
}

Function P2V_get_tenant_UI($tenantfile)
{ # funtion to select tenant via GUI  -> returns list (1..n  tenants)
  $t_list= @{}
  $t_resp= @{}
  $all_systems =import-csv $tenantfile 
  $all_systems |% {$t_list[$($_.tenant)]=$_}
  if (!$all_systems) {$form_err -f "[ERROR]"," tenantfile $tenantfile does not exist"; exit }
     
  $t_sel=$all_systems|select system,tenant, ServerURL |out-gridview -Title "select tenant(s)" -outputmode multiple

#  add baseauthstring to tenant
  $t_sel|%{ $t_resp[$_.tenant]=$t_list[$_.tenant];`
            $b=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t_list[$_.tenant].name, $t_list[$_.tenant].API)));`
            $t_resp[$_.tenant]| Add-Member -Name 'base64AuthInfo'  -Type NoteProperty -Value "$b" }
  
 # $t_resp|out-host
  return $t_resp
}

Function P2V_get_userlist($tenant)
{ # function to retrieve P2V userlist
   $tenantURL      ="$($tenant.ServerURL)/$($tenant.tenant)"
   $base64AuthInfo ="$($tenant.base64AuthInfo)"
   $API_URL        ="$tenantURL/PlanningSpace/api/v1/users?include=UserWorkgroups"
  
   $user_list=Invoke-RestMethod -Uri $API_URL -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
   if (!$user_list) {$form_err -f "[ERROR]", "cannot contact $tenant !" ;exit}
   return $user_list
}

Function P2V_get_AD_user($u_xkey)
{ # function to verify and request user
   
   $u_res="";
   while (!$u_res)
	 {
	 	while (!$u_key) {$u_key= Read-Host "Please enter user-xkey: (0=exit)"}
	    
		if ($u_key -eq "0") {return $False}
		
	    
		$u_res=Get-ADUser -Filter { (Name -like $u_key)} -properties * |select Name, Givenname, surname,UserPrincipalName, Department
					
		If (!$u_res) {$form_err -f "ERROR","$u_key not found in Active Directory"|out-host;$u_key=""}
		else
		{ 
		   $u_res.Department=$u_res.Department -replace '[,]', ''
		}
		$u_res |format-table   
	 }
     return $u_res					
} 

Function P2V_get_AD_user_UI($u_xkey)
{ # function to verify and select user  via GUI 
  # return values:
  # $u_res:  FALSE in case of error
  # $u_res:  userprofile:
  #            .Name, 
  #            .Givenname, 
  #            .surname,
  #            .SamAccountName,
  #            .UserPrincipalName, 
  #            .EmailAddress, 
  #            .Department,            
  #            .displayName,
  #            .logonID
  #--------------------------------
   $u_res="";
   while (!$u_res)
	 {
	 	while (!$u_key) {$u_key= Read-Host "|> Please enter user-searchstring (0=exit)"}
	    
		if ($u_key -eq "0") {$u_res="";return $False}
		
		#$u_res=Get-ADUser -Filter { (Name -like $u_key)} -properties * |select Name, Givenname, surname,UserPrincipalName, Department |out-gridview -Title "select user" -passthru
		#select Name,GivenName,Surname,UserPrincipalName,SamAccountName,EmailAddress,Department,Enabled,PasswordExpired ,LockedOut,lockoutTime, HomeDirectory 	
	    #$u_res=Get-ADUser -Filter { (Name -like $u_key)} -properties * |select Name, Givenname, surname,UserPrincipalName, Department
		$u_key='*'+$u_key+'*'
		$u_res=Get-ADUser -Filter { (Givenname -like $u_key) -or (Surname -like $u_key) -or (Name -like $u_key)} -properties * |select Name, Givenname, surname,SamAccountName,UserPrincipalName, EmailAddress, Department|out-gridview -Title "select user from AD" -outputmode single
		
		If (!$u_res) {$form_err -f "ERROR","$u_key not found or no user selected"|out-host;$u_key=""}
		else
		{ 
		   $u_res.Department=$u_res.Department -replace '[,]', ''
				
		  $u_res| Add-Member -Name 'displayName' -Type NoteProperty -Value "$($u_res.surname) $($u_res.Givenname) ($($u_res.SamAccountName))"
		  $u_res| Add-Member -Name 'logOnId' -Type NoteProperty -Value "$($u_res.UserPrincipalName)" 
		}
	}	 
     return $u_res					
} 

Function P2V_AD_userprofile($u_xkey) ##  CHECK - needed ?
{
  $u_ad_profile=@{}
  $u_ad_profile= Get-ADUser -Filter {Name -like $user} -properties *|select Name,GivenName,Surname,UserPrincipalName,SamAccountName,EmailAddress,Department,Enabled,PasswordExpired ,LockedOut,lockoutTime, HomeDirectory 
  

}

Function P2V_get_P2V_user_UI($t_sel)
{
   $u_res="";
   $authURL    ="$($t_sel.ServerURL)/identity/connect/token"
   $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t_sel.name, $t_sel.API)))
   $tenantURL  ="$($t_sel.ServerURL)/$($t_sel.tenant)"
   
   while (!$u_res)
	 {
	 	while (!$u_key) {$u_key= Read-Host "Please enter searchstring (0=exit)"}
	    
		if ($u_key -eq "0") {return $False}
		
		#$u_res=Get-ADUser -Filter { (Name -like $u_key)} -properties * |select Name, Givenname, surname,UserPrincipalName, Department |out-gridview -Title "select user" -passthru
		$u_res=Get-ADUser -Filter { (Givenname -like $u_key) -or (Surname -like $u_key) -or (Name -like $u_key)} -properties * |select Name, Givenname, surname,UserPrincipalName, Department|out-gridview -Title "select user" -outputmode single
		
	    
		#$u_res=Get-ADUser -Filter { (Name -like $u_key)} -properties * |select Name, Givenname, surname,UserPrincipalName, Department
					
		If (!$u_res) {$form_err -f "ERROR","$u_key not found in Active Directory"|out-host;$u_key=""}
		else
		{ 
		   $u_res.Department=$u_res.Department -replace '[,]', ''
		}
		$u_res |format-table   
	 }
     return $u_res					
} 

Function P2V_get_WG_UI($t_sel)
{
  # ---- not ready ----
   $wg_sel= @()
   
     while (!$u_res)
	 {
	 	while (!$u_key) {$u_key= Read-Host "Please enter searchstring (0=exit)"}
	    
		if ($u_key -eq "0") {return $False}
		
		#$u_res=Get-ADUser -Filter { (Name -like $u_key)} -properties * |select Name, Givenname, surname,UserPrincipalName, Department |out-gridview -Title "select user" -passthru
		$u_res=Get-ADUser -Filter { (Givenname -like $u_key) -or (Surname -like $u_key) -or (Name -like $u_key)} -properties * |select Name, Givenname, surname,UserPrincipalName, Department|out-gridview -Title "select user" -passthru
		
	    
		#$u_res=Get-ADUser -Filter { (Name -like $u_key)} -properties * |select Name, Givenname, surname,UserPrincipalName, Department
					
		If (!$u_res) {$form_err -f "ERROR","$u_key not found in Active Directory"|out-host;$u_key=""}
		else
		{ 
		   $u_res.Department=$u_res.Department -replace '[,]', ''
		}
		$u_res |format-table   
	 }
     return $u_res					
} 

# Function to invoke interactive login via browser
Function Get-PlanningSpaceAuthToken ($tenantUrl)
{
    Add-Type -AssemblyName System.Windows.Forms

    $tenantUrl = $tenantUrl.Trim("/") + "/"
    $url = [System.Uri]$tenantUrl
    $script:returnUrl = ""

    $authUrl = "{0}/identity/connect/authorize?response_type=token&state=foo&client_id={1}%20web&scope=planningspace&redirect_uri={2}loginCallback.html" `
        -f $url.GetLeftPart([System.UriPartial]::Authority), $url.Segments[1].Trim("/"), [System.Uri]::EscapeUriString($tenantUrl)

    $popupForm = New-Object -TypeName System.Windows.Forms.Form -Property @{Width=500;Height=700}
    $browser  = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{Url=$authUrl}
    $completedHandler  = {
            $script:returnUrl = $browser.Url.AbsoluteUri
            if ($script:returnUrl -match "error=[^&]*|access_token=[^&]*")
            {
                $popupForm.Close() 
            }
    }
    
    $browser.Add_DocumentCompleted($completedHandler)
    $popupForm.Controls.Add($browser)
    $browser.Dock = [System.Windows.Forms.DockStyle]::Fill

    $popupForm.Add_Shown({$popupForm.Activate()})
    $popupForm.ShowDialog() | Out-Null

    [RegEx]::Match(([System.Uri]$script:returnUrl).Fragment, "(access_token=)(.*?)(&)").Groups[2].Value
}

#---   get filename from
Function Get-FileName($initialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "CSV (*.csv)| *.csv"
    $OpenFileDialog.ShowDialog() | Out-Null
    return $OpenFileDialog.filename
}

Function Write-Log([string]$logtext, [int]$level=0)
{
	$logdate = get-date -format "[yyyy-MM-dd HH:mm:ss]"
	if($level -eq 0) {$severity="[INFO]"}
	if($level -eq 1) {$severity="[WARNING]"}
	if($level -eq 2) {$severity="[ERROR]"}
	
	$text= "$logdate - "+ "$severity "+ $logtext
	$text >> $logfile
}

Function show_progress ([int]$i=0 )
{
 $progress=@("[/]`b`b`b","[-]`b`b`b","[\]`b`b`b","[|]`b`b`b")
 #$i=$i%4
 write-host -nonewline -ForegroundColor green $progress[$i%4]
}


# central configurations
# layouts
$global:linesep    ="+-------------------------------------------------------------------------------+"

$global:form1      ="|  {0,-75}  |"
$global:form2      ="|  {0,-12} {1,-62}  |"
$global:form2_1    ="|  {0,-37} {1,37}  |"
$global:form3      ="|  {0,-12} {1,-50} {2,-12} |"
$global:form4      ="|  {0,-12} {1,-24} {2,-24} {3,-12}  |"
$global:form_status="|  {0,-62} {1,-12}  |"
$global:form_err   ="|>>{0,-12} {1,-62}<<|"
$global:form_user  ="|  {0,-5} {1,-29} {2,-40} |"
$global:form_user1 ="|  {0, 5} {1,-57} {2,-12} |"
 
#         0         1         2         3         4         5         6         7         8

# global variables
$global:output_path_base = "\\somvat202005\PPS_share\P2V_UM_data\output"
$global:dashboard_path = $output_path_base + "\dashboard"
$global:log_path    = $output_path_base + "\logs"

$logfile    		 = $log_path +("\P2V_Usermgmt_Log" + $date + ".log")

createdir_ifnotexists ($output_path_base)
createdir_ifnotexists ($dashboard_path)
createdir_ifnotexists ($log_path)

$global:lib_path    = $workdir + "\lib"

$global:config_path = "\\somvat202005\PPS_share\P2V_UM_data\conf"
$global:adgroupfile = $config_path + "\all_adgroups.csv"
$global:tenantfile  = $config_path + "\all_tenants.csv"
$global:profile_file= $config_path + "\P2V_profiles.csv"
$global:date = get-date -format "yyyy-MM-dd"



