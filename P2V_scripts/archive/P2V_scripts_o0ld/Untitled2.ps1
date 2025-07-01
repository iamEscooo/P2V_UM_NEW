$My_path=Split-Path $($MyInvocation.MyCommand.Path)
$workdir=$My_Path
$scripts=@()
$scripts+=$workdir + "\check_AD_userprofile.ps1"
$scripts+=$workdir + "\check_P2V_user.ps1"
$scripts+=$workdir + "\create_lic_file.ps1"
$scripts+=$workdir + "\PS-export_users_003.ps1"
$scripts+=$workdir + "\PS-auditlogs.ps1"
$scripts+=$workdir + "\create_lic_file.ps1"

$scripts

".."

foreach ($i in 1..$scripts.count) {
write-host $i $scripts[$i-1]
}
"..."
$scripts.count
