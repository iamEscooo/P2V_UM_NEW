#-----------------------------------------
# sync user base 
#
#  name:   P2V_sync_userbase.ps1 
#  ver:    0.1
#  author: M.Kufner
#
# retrieve AD-settings for specific x-key
# arguments:
# $long =  false (default)   - short summary 
# $long =  true              - all AD entries
# $P2Vgroups = true (default)/false   - show P2V AD group memberships
#-----------------------------------------
param(
  [string]$tenant="",
  [bool]$lock=$False,
  [bool]$deactivate=$False,
  [bool]$checkOnly = $False
)
#-------------------------------------------------
$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir\P2V_include.ps1"

#----- Set config variables

$output_path = $output_path_base + "\$My_name"
createdir_ifnotexists($output_path)

#$spec_accounts = @("adminx449222@ww.omv.com","adminarun05")
#----- start main part
P2V_header -app $My_name -path $My_path 

if(!$tenant) {$t_sel= P2V_get_tenant($tenantfile)}
$tenant=$t_sel.tenant

$authURL    ="$($t_sel.ServerURL)/identity/connect/token"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $t_sel.name, $t_sel.API)))
$tenantURL  ="$($t_sel.ServerURL)/$($t_sel.tenant)"
$AD_group   = $t_sel.ADgroup
$vendor_group= "dlg.WW.ADM-Services.P2V.Aucerna"

#-- select users 
$u1_list_vendor=@{}
$u1_list_P2V=@{}
$u1_list_AD =@{}

#-- get P2V user list
$u_list_P2V=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users?include=UserWorkgroups" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
if (!$u_list_P2V) {$form_err -f "[ERROR]", "cannot contact $tenant !" ;exit}
$u_list_P2V= $u_list_P2V | where-Object { $_.authenticationMethod -ne "LOCAL" } 

$form_user1 -f $u_list_P2V.count, "non-local users loaded from $tenant",""

#$u_list_P2V|select id,displayname,description,IsAccountLocked,isDeactivated |format-table
$u_list_P2V|% {$u1_list_P2V[$($_.logonID)]=$_}

#-- get AD -user list

$u_list_AD =Get-ADGroupMember -Identity $AD_group|Get-ADUser -properties * |Select Surname,GivenName,Name,UserPrincipalName, Department, EmailAddress 
$u_list_AD |% {$u1_list_AD[$($_.UserPrincipalName)]=$_}

$form_user1 -f $u_list_AD.count, "users loaded from AD [$AD_group]",""


$u_list_vendor=Get-ADGroupMember -Identity $vendor_group|Get-ADUser -properties * |Select Surname,GivenName,Name,UserPrincipalName, Department, EmailAddress 
$u_list_vendor |% {$u1_list_vendor[$($_.UserPrincipalName)]=$_}

#$u_list_AD|format-table

#$u_list_P2V|select logonID|out-gridview
#$linesep|out-host
#$u_list_AD |select UserPrincipalName|out-gridview


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
$linesep
foreach ($u1 in $($u1_list_P2V.keys))
{
   if ($spec_accounts -contains $u1) {$form_status -f "* special account $u1","[SKIP]"} # skip spec. accounts (e.g. adminx449222@ww)
   else{
    $change_ops=@()
	$del_ops=@()
			
    if ($u1_list_AD.ContainsKey($u1))
    {
      #-- user found - update infos
	  $u_ad   = $u1_list_AD[$u1]
	  $u_p2v  = $u1_list_P2V[$u1]
	  #$form1 -f "$($u_ad.UserPrincipalName) found - update details"
	  
	  #-- create update ops
  
      $descr = $u_ad.Department -replace '[,]', ''
	  $descr = $descr.trim()
	  $dname = "$($u_ad.Surname) $($u_ad.GivenName) ($($u_ad.name))"
      $authenticationMethod = "SAML2"
      $isDeactivated        = $False
      $isAccountLocked      = $False
      $useADEmailAddress    = $False
	  $emailAddress         = $u_ad.EmailAddress
	  
	   # if($dname -ne $u_p2v.displayname)
	   # { $change_ops += [PSCustomObject]@{  
                  # op = "replace"
                  # path = "/displayName"
                  # value = $dname
              # } 
	   # }
	  if ($u1_list_vendor.ContainsKey($u1))
	  { $descr = "[AUCERNA] "+$descr}
	  	  
	  if($descr -ne $u_p2v.description)
	  { 
	   
	   $change_ops += [PSCustomObject]@{  
                 op = "replace"
                 path = "/description"
                 value = $descr
             } 
	  }
             
      If ($($u_p2v.useADEmailAddress))
	  { $change_ops += [PSCustomObject]@{
                 op = "replace"
                 path = "/useADEmailAddress"
                 value = $False
			 }
      }			 
	  
	  if($emailAddress -ne $u_p2v.emailAddress)
	  { 
	   	   $change_ops += [PSCustomObject]@{  
                 op = "replace"
                 path = "/emailAddress"
                 value = $emailAddress
             } 
	  }
	   
	  
	
      if ($u_p2v.isDeactivated)
	  { $change_ops += [PSCustomObject]@{
                 op = "replace"
                 path = "/isDeactivated"
                 value = $False
             }
	  }
	  if ($u_p2v.isaccountlocked)
	  {	$change_ops += [PSCustomObject]@{  
                 op = "replace"
                 path = "/isAccountLocked"
                 value = "False"
            }
      }			
      if ($change_ops.count -gt 0)
	  {$ccount +=1
	  $form_status -f "$($u_ad.UserPrincipalName) found","[UPDATE]"
	  } 
	} else
    { #-- user not entitled -> deactivate
   
      $u_p2v=$u1_list_P2V[$u1]
	 	  
	  
	  if (!($u_p2v.isDeactivated))
	  { 
	     $form_status -f "$($u_p2v.logonID)  in P2V but not in AD","[DEACTIVATE]"
	     $del_ops += [PSCustomObject]@{
                 op = "replace"
                 path = "/isDeactivated"
                 value = "True"
         }
	     $dcount +=1 
	  }else
	  {
	    #$form_status -f "$($u_p2v.logonID)  already deactivated","[SKIP]"
		$scount++
	  }
     }
	 
   if ($($change_ops.count) -gt 0){ $updateOperations[$u_p2v.id.ToString()] = $change_ops  }  
   if ($($del_ops.count) -gt 0)   { $deleteOperations[$u_p2v.id.ToString()] = $del_ops  }    
   }
}
$form_status -f "$scount accounts already deactivated","[SKIP]"
$linesep
foreach ($u2 in  $u1_list_AD.keys)
{
   if ($u1_list_P2V.ContainsKey($u2))
   {
   # /-- no ops - already done 
   }
   else
   {
      #-- user not existing -> create
      $u_ad_sel=$u1_list_AD[$u2]
	  #$u_p2v_sel=$u1_list_P2V[$u2]
      	 
	  $form_status -f "$($u_ad_sel.UserPrincipalName)  in AD but not in P2V","[CREATE]"
	  	  
	  $add_ops += [PSCustomObject]@{
                logOnId = $u_ad_sel.UserPrincipalName
                displayName = "$($u_ad_sel.Surname) $($u_ad_sel.GivenName) ($($u_ad_sel.name))"
                description = $u_ad_sel.Department -replace '[,]', ''
                isDeactivated = $False
                isAccountLocked = $False
                authenticationMethod = "SAML2"
				useADEmailAddress    = $True
            }
     }
}
$linesep
$acount=$add_ops.count

if (($cont=read-host ($form1 -f "add $acount users? (y/n)")) -like "y")	
{
     if ($($add_ops.count) -gt 0)   
	 { 
	   $linesep
	   $form1 -f "..adding users"
	      
       if (!$checkOnly) 
       {
	     
	     foreach ($a in $add_ops)
		 {
	        $body = $a|convertto-json
			$body = [System.Text.Encoding]::UTF8.GetBytes($body)
			$result = Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users" -Method Post -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ($body) -ContentType "application/json"
			if ($result) {$rc="[DONE]"}else {$rc="[ERROR]"} 
		    
			$form_status -f $a.displayName,$rc
			
		}
	   }
	 }
 }

if (($cont=read-host ($form1 -f "update $ccount users? (y/n)")) -like "y")	
{
    if ($($updateOperations.count) -gt 0)   
	{  
	   $linesep|out-host
	   $form1 -f "..updating users"|out-host
	   $updateOperations |format-table|out-host
	   if (!$checkOnly) 
       {
    	  $result = Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users/bulk" -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ($updateOperations|ConvertTo-Json) -ContentType "application/json" 
  	      $result  |format-list|out-host 
	   }
	}
}


$deleteOperations=$deleteOperations|out-gridview -title "select users to deactivate"  -outputmode multiple

if (($cont=read-host ($form1 -f "deactivate $dcount users? (y/n)")) -like "y")	
{
    if ($($deleteOperations.count) -gt 0)   
	{
       $linesep
	   $form1 -f "..deactivating users"
       #$deleteOperations |convertto-Json  	
       if (!$checkOnly) 
       {
	     $result = Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users/bulk" -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ($deleteOperations|ConvertTo-Json) -ContentType "application/json"
	     $result  |format-list|out-host 	 
	   }
	}
}




P2V_footer -app $My_name

pause

