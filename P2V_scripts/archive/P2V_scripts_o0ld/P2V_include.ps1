#=======================
#  P2V_include.ps1
#  V 0.1
#  
#  specific P2V function 
#
#  Martin Kufner
#=======================

#-- Function to invoke interactive login via browser
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

Function P2V_layout()
{
return $True
}

# header
Function P2V_header
{ 
	param (
	[string]$app="--script name--",
    [string]$path="--working directory--"
	)
	$user=$env:UserDomain+"/"+$env:UserName
	$client=$env:ComputerName
	
	$linesep |out-host
    # $form2_1 -f "[$app]",(get-date -format "dd/MM/yyyy HH:mm:ss")  |out-host
    # $form2_1 -f "[$path]","[$user]"|out-host
	$form2_1 -f "[$app]","[$path]"|out-host
	$form2_1 -f "[$user] on [$client]",(get-date -format "[dd/MM/yyyy HH:mm:ss]")  |out-host    
	write-log "[$user] on [$client] started [$app]"
	$linesep|out-host
}

# footer
Function P2V_footer
{ 
    param (
	[string]$app="--end of script--",
    [string]$path=(get-date -format "dd/MM/yyyy HH:mm:ss")  
	)
   $linesep|out-host
   $form2_1 -f "[$app]$form", "$path"  |out-host
   $linesep|out-host
}

#show_menu
Function P2V_Show-Menu
{
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

# Function to delete existing files
Function Delete-ExistingFile
{
	param(
	         [string]$file_to_delete,
	         [bool]$verbose=$false
	      )
	
    if (Test-Path $file_to_delete) 
    {
        Remove-Item $file_to_delete
		$msg="[$file_to_delete] deleted"
	    if ($verbose) {$form_status -f $msg,"[DONE]"}
	    Write-Log $msg
    }
}


Function createdir_ifnotexists ([string]$check_path,[bool]$verbose=$false)
{
      If(!(test-path $check_path))
	  {
	   $c_res=New-Item -ItemType Directory -Force -Path $check_path 
	   $msg="directory $checkpath created"
	   if (!$verbose) {$form_status -f $msg,"[DONE]"}
	   Write-Log $msg
	   $c_res
	   }
}

# funtion to print P2V user profile
Function P2V_print_user($uprofile)
{
	  $form2_1 -f 'id',$r.id |out-host
	  $form2_1 -f 'logOnId',$r.logOnId|out-host
	  $form2_1 -f 'displayName',$r.displayName|out-host
	  $form2_1 -f 'isAccountLocked',$r.isAccountLocked|out-host
	  $form2_1 -f 'isDeactivated', $r.isDeactivated|out-host
      out-host
}

# funtion to select tenant
Function P2V_get_tenant($tenantfile)
{
  
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

#function to verify and request user
Function P2V_get_AD_user($u_xkey)
{
   
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
{
   
   $u_res="";
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
    $OpenFileDialog.filename
}



function Write-Log([string]$logtext, [int]$level=0)
{
	$logdate = get-date -format "[yyyy-MM-dd HH:mm:ss]"
	if($level -eq 0) {$severity="[INFO]"}
	if($level -eq 1) {$severity="[WARNING]"}
	if($level -eq 2) {$severity="[ERROR]"}
	
	$text= "$logdate - "+ "$severity "+ $logtext
	$text >> $logfile
}

function show_progress ([int]$i=0 )
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
$global:form_status="|  {0,-63} {1,-12} |"
$global:form_err   ="|>>{0,-12} {1,-62}<<|"
$global:form_user  ="|  {0,-5} {1,-29} {2,-40} |"
$global:form_user1 ="|  {0, 5} {1,-57} {2,-12} |"
 
    #         0         1         2         3         4         5         6         7         8

# global variables
$global:config_path = $workdir + "\config"
$global:log_path    = $workdir + "\logs"
$global:lib_path    = $workdir + "\lib"
$global:adgroupfile = $config_path + "\all_adgroups.csv"
$global:tenantfile  = $config_path + "\all_tenants.csv"
$global:profile_file= $config_path + "\P2V_profiles.csv"
$global:date = get-date -format "yyyy-MM-dd"
$logfile     = $log_path +("\P2V_Usermgmt_Log" + $date + ".log")

createdir_ifnotexists ($log_path)
