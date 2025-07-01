<#
P2V_profile_manager_file

load profile definition from file -> generate user <> workgroup assignment

#>
param(
  [bool]$debug = $False,
  [bool]$checkonly = $False
)
#-------------------------------------------------

$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir/P2V_include.ps1"

#----- Set config variables
$output_path = $output_path_base + "\$My_name"
$Prof_logfile= $output_path + "\profiles.log"


#-------------------------------------------------
P2V_header -app $My_name -path $My_path 
createdir_ifnotexists($output_path)

#-------------------------------------------------
#P2V_layout 

$P2V_profile=@{}
$add_log =@()
$delete_log =@()

#-- 1#   read profiles
<# $csv_profiles=import-csv -path $profile_file |sort profile
$l1=""
$g_list=@()
foreach ($l in $csv_profiles) 
{
  if ($($l.profile) -eq $l1) {$g_list+=$l.groups}
  else
  {
    If ($l1) 	
	{
	  $P2V_profile[$l1]=$g_list
	  $g_list=@()
	}
	$g_list+=$l.groups
    $l1=$l.profile 
  } 
}
 #> 
 
 foreach ($l in (import-csv -path $profile_file |sort profile)) 
 {
    $profile=$l.profile
	
	If ( $P2V_profile.Keys -contains "$profile") { $P2V_profile["$profile"] += $l.groups } 
	     else                                 	 { $P2V_profile["$profile"]  = @($($l.groups)) }
 }

 
$form_status -f "load profile definitions $profile_file","[DONE]"
$linesep

$csv_profiles|convertto-Json|out-file "$output_path\csvprofiles.json"

#-- 2# select tenant

$tenants= select_PS_tenants -multiple $false

foreach ($ts in $tenants.keys)
{
   $t           = $tenants[$ts]
   $tenant      = $t.tenant
   $PS_user_1   = @{}
   $u_sel	    = @{}
   $tenantURL   ="$($t.ServerURL)/$($t.tenant)"
   $base64AuthInfo = "$($t.base64AuthInfo)"
   $profiles_U  = $output_path + "\$($tenant)_profiles.csv"
   $profiles_UG = $output_path + "\$($tenant)_profiles_UG.csv"
   
   Delete-ExistingFile $profiles_UG
   
   if (! (Test-Path $profiles_UG)) { Add-Content -Path $profiles_UG -Value 'LogonId,Workgroup'}
   #-- 3  retrieve all workgroups
   #--  retrieve group-list
   $w_result= get_PS_grouplist -tenant $t   
      
   #-- 4 select (multiple) user(s)
   $PS_users= get_PS_userlist -tenant $t
   if (!$PS_users) {exit}
   $PS_users|% {$PS_user_1[$($_.logOnId)]=$_}	 	 
   $linesep
   $form1 -f "Please check changes before continuing.."
   $form1 -f " in tenant $tenant the following changes are requested"
   $linesep
   $UP_lookup= @{}
 
   Write-host "select user<> profile assignment file: "
   $workgroupsFile = Get-FileName ($output_path)
    
   #    $UP_csv =    Import-Csv $workgroupsFile 
          
    foreach ($up in (Import-Csv $workgroupsFile)) 
	{
	  $LogonId=$up.logOnId
		 If ( $UP_lookup.Keys -contains  "$LogonId") { $UP_lookup["$LogonId"] +=$up.Profile } 
	     else                                 	 { $UP_lookup["$LogOnId"] = @($($up.profile)) }
    }
      
   #$up_lookup|format-table|out-host
   #$P2V_profile.GetEnumerator()|sort-object -Property Name |format-table|out-host
   
   $U_G= @{}
   
   foreach ($u in $UP_lookup.keys)
   {  # for each user
      $count_u=0
      foreach ($p in $UP_lookup["$u"])
	  { # for each profile
	      foreach ($g in $P2V_profile["$p"])
		  { # foreach group
		    $count_u++
		 	$form3_2 -f "$u", $p, $g|out-host
			if ($U_G.Keys -contains $u)  { if ($U_G["$u"] -notcontains "$g") {$U_G["$u"]+= $g } }
			  else                         { $U_G["$u"] = @($g)}			
			"$u,$g"|out-file $profiles_UG -Append -Encoding utf8
			#Add-content $profiles_UG -Value ($u + "," + $g )
			
		  }
	  }
	   write-host ( "[" + $U_G["$u"].count + " / $count_u ]")
	 
    }
   
   
   
   pause 
   exit
   
   $user_profiles=
   if (! (Test-Path $profiles_U))  { Add-Content -Path $profiles_U  -Value 'LogonId,Profile'}
   if (! (Test-Path $profiles_UG)) { Add-Content -Path $profiles_UG -Value 'LogonId,Workgroup'}
   	
   $form3_2 -f "user" , "profile", "workgroup"
   $form3_2 -f "===========","===========","==========="
   
   while ($u_s=$PS_users |select id,displayName,logOnId,description,authenticationMethod,emailAddress,isDeactivated,isAccountLocked|out-gridview -title "select user" -outputmode multiple)
   {
       #-- 5 select profile to apply
       $profile_sel=$P2V_profile|sort-object Name|out-gridview -title "Select Profile to apply"  -outputmode multiple
     
       $csv_profiles|where { $($_.profile) -eq $($profile_sel.Value)}

       $updateOperations = @{}

        #-- continue?
       
     	
       foreach($u in $u_s)
       {
           $u_sel[$($u.logOnId)]=$PS_user_1[$($u.logonId)]
	   
           foreach ($p in  $profile_sel) 
	       {
    	       # $p|format-list|out-host
		   
	           #$form2_2 -f "$($u.logonId)" , "$($p.key)"
		   
             # $form1 -f $p.key
               $p.value|%{ Add-Content  $profiles_UG -Value ( $($u.logonId) + "," + $($_) );
			               $form3_2 -f "$($u.logonId)","$($p.key)","$($_)" }
		       Add-Content  $profiles_U -Value ( $($u.logonId) + "," + $($p.key) )
           }
       }
   }
   $linesep
   out-host
  }

  
P2V_footer -app $My_name
Read-Host "Press Enter to close the window"

exit 
# ----- end of file -----
