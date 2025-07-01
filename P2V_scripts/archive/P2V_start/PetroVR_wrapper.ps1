#---
#
param  (
	 [string] $tenant="" 
	 )
# )
$show_info=$true
$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir\WPFMessagebox.ps1"

#$conf_dir="$workdir\conf"
$conf_dir="\\somvat202005\PPS_share\P2V_UM_data\startup_message"
$msg_file="$conf_dir\message.csv"

$InfoParams =@{}

$msg_to_show=import-csv $msg_file  |where { ($($_.app) -like "$tenant")-or ($($_.app) -like "ALL")}


foreach ($m in $msg_to_show)
{
switch ($($m.severity))
{
"warning" 	
			{
				$InfoParams= @{
					Title = "WARNING"
					TitleFontSize = 20
					TitleBackground = 'Orange'
					TitleTextForeground = 'Black'
				}
			}

"information"
			{
				$InfoParams= @{
					Title = "INFORMATION"
					TitleFontSize = 20
					TitleBackground = 'LightSkyBlue'
					TitleTextForeground = 'Black'
				}
			}
}
 if (test-path ("$conf_dir\$($m.msgfile)"))
 {
  $body=Get-content -Path "$conf_dir\$($m.msgfile)" -Raw
  "$conf_dir\$($m.msgfile)"
  if ($show_info) {P2V-WPFMessageBox @InfoParams -Content "$body"}
 }
 else
  {"no msg to display"}
}

$app="C:\Program Files (x86)\Palantir\PetroVR\PetroVR.exe"

if ($app_arg) {Start-Process -FilePath "$app" -ArgumentList "$app_arg"}
else          {Start-Process -FilePath "$app"}


pause