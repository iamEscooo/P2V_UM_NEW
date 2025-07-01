
param (
  $config = "\\somvat202005\PPS_share\P2V_UM_data\sec 2.0\P2V_adgroups.csv",
  $output = "\\somvat202005\PPS_share\P2V_scripts\TEMP\P2V_ADgroups.csv"
)
# set input file  (match AD-group <-> P2V profile)
$ad_group_file= $config
# set output file 
$output_file=  $output

$group_match=@{}

$group_assign=@{}
$group_members=@{}
$all_users=@{}
$out_list=@()
$out_item=@{}

write-output "<---  loading configs --->"
$group_match= import-csv $ad_group_file

$group_match|%{$group_assign[$($_.ADgroup)]=$_     

                    }

if (Test-Path $output_file) 
    {
        Remove-Item $output_file
		$msg="[$output_file] deleted"	   
    }

# all user-ad file
#Add-Content -Path $output_file -Value 'DisplayName,xkey,LogonId,ADgroup,PSprofile'

write-output "<---  loading AD groups and members --->"
foreach ($g in (Get-ADgroup -Filter '(ObjectClass -eq "group" -and 
             (sAMAccountName -like "dlg.WW.ADM-Services.P2V*" -or sAMAccountName -like "dlg.WW.ADM-Services.PetroVR*") )'|select Name))
{
    write-output "AD-group:  [$($g.Name)] ->  PS-profile: [$($group_assign[$($g.Name)].PSgroup)]"

    Get-ADGroupMember -Identity $g.Name|Get-ADUser -properties * |Select Surname,GivenName,Name,UserPrincipalName, Department, EmailAddress|% {
              $group_members["$($g.Name)"]+=@($_);
           
              #Add-Content -Path $output_file  -Value ("$($_.Surname) $($_.GivenName) ($($_.Name)),$($_.Name),$($_.UserPrincipalName),$($g.Name),$($group_assign[$($g.Name)].PSgroup)")
              $out_item= [PSCustomObject]@{
              DisplayName = "$($_.Surname) $($_.GivenName) ($($_.Name))"
              xkey        = "$($_.Name)"
              LogonId     = "$($_.UserPrincipalName)"
              ADgroup     = "$($g.Name)"
              PSprofile   = "$($group_assign[$($g.Name)].PSgroup)"
              }

              $out_list += @($out_item)
          
          }


          $count=  $group_members["$($g.ADgroup)"].count

          
}
write-output "<---  writing output --->"
#$out_list|ft

$out_list |Export-Csv -path $output_file -NoTypeInformation -Encoding utf8

write-output "<---  finished --->"
