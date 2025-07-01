# check json -format profiles


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
#P2V_layout 

$P2V_profile=@{}

#-- 1#   read profiles
$csv_profiles=import-csv -path $profile_file |sort profile
$l1=""
$g_list=@()
foreach ($l in $csv_profiles) 
{

    if ($P2V_profile.containskey("$($l.profile)"))
	{ 
    	$P2V_profile["$($l.profile)"].groups+=$l.groups
	}
	else
	{
         $new_entry = [PSCustomObject]@{
  				profile				 = "$($l.profile)"
                pgroup               = "$($l.user)"
                groups 	        	 = @("$($l.groups)")
				type				 = "$($l.type)"
				lic                  = "$($l.lic)"
            }
			$P2V_profile["$($l.profile)"]=$new_entry
    }
	
  # if ($($l.profile) -eq $l1) {$g_list+=$l.groups}
  # else
  # {
    # If ($l1) 	
	# {
	  # $P2V_profile[$l1]=$g_list
	  # $g_list=@()
	# }
	# $g_list+=$l.groups
    # $l1=$l.profile 
  # }
}

$P2V_profile.GetEnumerator() | sort -Property key |convertto-json|out-file "$output_path\Xprofiles1.json"
$P2V_profile|convertto-json|out-file "$output_path\Xprofiles.json"




