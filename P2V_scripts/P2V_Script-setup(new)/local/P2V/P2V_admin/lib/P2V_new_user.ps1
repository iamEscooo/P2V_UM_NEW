#=======================
#  create new user
#
#  name:   P2V_new_user.ps1 
#  ver:    1.0
#  author: M.Kufner
#=======================

param(
  [string]$user="<no xkey>",
  [string]$tenant="",
  #[bool]$toggle=$True,
  [bool]$checkonly = $False
)
#-------------------------------------------------

$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir/P2V_include.ps1"

#-------------------------------------------------
#  Set config variables

$output_path = $output_path_base + "\$My_name"

$u_w_file= $output_path + "\Myuserworkgroup.csv"

#-------------------------------------------------
#layout
#P2V_layout 
P2V_header -app $My_name -path $My_path 
$newUsers =@()

#1  check tenant /select tenant
if(!$tenant) {$t= P2V_get_tenant($tenantfile)}
$tenant=$t.tenant

$authURL    ="$($t.ServerURL)/identity/connect/token"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t.name, $t.API)))
$tenantURL  ="$($t.ServerURL)/$($t.tenant)"


#2  get userprofile from AD-groups


if (!($u_result= P2V_get_AD_user_UI($user))) {exit}
   
$newUsers =@()
$user =  $u_result.Name   #xkey
$UPN  =  $u_result.UserPrincipalName


#3  create user
   If($user)
   {
   
    $form1 -f "New user $($user) will be created in [$tenant]"
    $newUsers += [PSCustomObject]@{
      logOnId              = "$UPN"
      authenticationMethod = "SAML2"
      displayName          = "$($u_result.Surname) $($u_result.GivenName) ($user)"
      description          = "$($u_result.Department)"
      isDeactivated        = "False"
      isAccountLocked      = "False"
     # useADEmailAddress    = $True
    }
  }

$newUsers
$linesep

   $newUsers=@($newUsers) 

$newUsers
$linesep
    
   #  {  #/planningspace/api/v1/users/bulk
   if (($cont=read-host "continue (y/n)") -like "y")
   {
      if ($newUsers.Count -gt 0)
      {
		    $form1 -f  "Creating new users..."
			$ApiURL="$tenantURL/PlanningSpace/api/v1/users/bulk"
			$form1 -f $ApiURL
			ConvertTo-Json @($newUsers)
#	        Try {
			#$iu_result=
			Invoke-RestMethod -Uri $ApiURL -Method Post -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body (ConvertTo-Json @($newUsers)) -ContentType "application/json"
 #           }
#			catch
			# {
			 # Write-Host "An error occurred:"
              
             # write-error $("Fehler aufgetreten:" + $_.Exception.GetType().FullName); 
   # write-error $("Fehler aufgetreten:" + $_.Exception.Message); 
			# }
            If (!$iu_result) 
			  { 
			  $form_status-f "insert failed","[ERROR]" 
			    }
            else 
			  {
                Write-Output " Creation result:"
                $iu_result | Write-Output
                Write-Output "Finished creating new users."
			  }
	   }
	 }
	  else
     {
		  ConvertTo-Json @($newUsers)|out-host
	 }
  
#4  check:  retrieve P2V userprofile
$resp=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
if (!$resp) {$form2_1 -f "[ERROR]", "cannot contact $t !" ;break}
$resp=$resp |where {($($_.logOnId) -like $user) -or ($($_.logOnId) -like $UPN )}
$resp

