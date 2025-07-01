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
$conf_dir_base="\\somvat202005\PPS_share\P2V_UM_data"
$conf_dir_msg="$conf_dir_base\startup_message"
$conf_dir="$conf_dir_base\conf"
$tenantfile="$conf_dir\all_tenants.csv"
$msg_file="$conf_dir_msg\message.csv"

$tenant_sel =import-csv $tenantfile|select system,ServerURL,tenant
$t =$tenant_sel |where {$($_.tenant) -like $tenant}

$t|format-list
if ($tenant_1 ="") {"wrong argument: tenant $tenant does not exist";exit}

$app="C:\Program Files\Palantir\PlanningSpace 16.5\PlanningSpace\PlanningSpace.exe"
$app_arg="/tenanturl=$($t.ServerURL)/$($t.tenant)"
"Start-Process -FilePath $app -ArgumentList $app_arg"
out-host
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
 if (test-path ("$conf_dir_msg\$($m.msgfile)"))
 {
  $body=Get-content -Path "$conf_dir_msg\$($m.msgfile)" -Raw
  "$conf_dir_msg\$($m.msgfile)"
  if ($show_info) {P2V-WPFMessageBox @InfoParams -Content "$body"}
 }
}


 if ($show_info) {P2V-WPFMessageBox @InfoParams -Content "$body"}
 if ($show_info) {P2V-WPFMessageBox @InfoParams -Content "APP:        $app" }
 if ($show_info) {P2V-WPFMessageBox @InfoParams -Content "ARGUMENTS:  $app_arg " }
"Start-Process -FilePath $app -ArgumentList $app_arg"|out-host
pause

P2V-WPFMessageBox @InfoParams -Content "Select Tenant to start" -ButtonType 'None' -CustomButtons @("PPS-DEV","P2V-PROD","P2V_DEMO","P2V_TEST")


if ($app_arg) {Start-Process -FilePath "$app" -ArgumentList "$app_arg"}
else          {Start-Process -FilePath "$app"}


