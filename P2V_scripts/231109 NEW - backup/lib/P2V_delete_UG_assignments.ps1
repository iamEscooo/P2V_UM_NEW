<#
P2V_delete_UG_assignments.ps1




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
$ulist= @()
$tenants= select_PS_tenants -multiple $false

foreach ($ts in $tenants.keys)
{
   $t=$tenants[$ts]
   $tenant=$t.tenant
   $linesep
   $form1 -f "  >>> $tenant <<<"
   $tenantURL  ="$($t.ServerURL)/$($t.tenant)"
   $base64AuthInfo = "$($t.base64AuthInfo)"

   $currentUsers      = get_PS_userlist -tenant $t
   $currentWorkgroups = get_PS_grouplist -tenant $t
   
   $u_sel=$currentUsers| Out-gridview -title "select user to clean"  -outputmode "multiple"
   $u_sel|%{$uid=$_.logonid;
   $ulist+=$currentUsers|where {$($_.logonid) -eq $uid}
   }
   
   foreach ($u in $ulist)
   {
       $form1 -f "     >>> user: $($u.displayname) <<<"
	   write-host -nonewline "|  remove workgroup memberships ..`r"
	   PS_user_clear_all_workgroups -tenant $t -logonID $u.logonid
	   $form_status -f "removing workgroup memberships","[DONE]"
	   
       $tmp_u= get_ps_user -tenant $t -logonID $u.logonid 
   	   
   }
   
}
      


P2V_footer -app $My_name
Read-Host "Press Enter to close the window"
# ----- end of file -----


