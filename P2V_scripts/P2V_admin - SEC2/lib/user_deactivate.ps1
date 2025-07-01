
#+--------------------------+
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

#-------------------------------------------------
P2V_header -app $My_name -path $My_path 
createdir_ifnotexists($output_path)

#-------------------------------------------------
$selected_tenants=@()
# 1   get_tenant(s)

$selected_tenants=select_PS_tenants()


foreach ($tenant in $selected_tenants)
{
  # ---
  # 2 - get userlist

  
  
  foreach ($user in $userlist)
  {
  
    # if user is deactivated
    # ---
    #   create (delete-list )
	 foreach ($uid in $u_sel)
  {
	 $del_ops =@()
     $delete_ops= @{}
	 
	 # missing part:  remove list of existing group assignments
	  
     foreach( $g in $uid.userworkgroups)
     {
        $hash = @{}
        $g | Get-Member -MemberType Properties | select -exp "Name" | % { $hash[$_] = ($g | SELECT -exp $_) }
        foreach($wg in ($hash.Values | Sort-Object -Property id)) 
        {
	       if ($($wg.id) -ne "2")  # skip Everyone group 2
		   { 
			  $del_ops = [PSCustomObject]@{
                    op = "remove"
                    path = "/users/$($uid.id)"
                    value = ""							
		      }
			  $form_status -f " [$($uid.displayName)] group $($wg.id) / $($wg.name)","[REMOVE]"
			  			  $delete_ops["$($wg.id)"] =@($del_ops)
		   }
		}
	 }
	 	
	 $user_ops["$($uid.id)"]=$delete_ops
	
    }
	
	
	
	
  }
  
  
  
  
  
  
}