#---
#
$show_info=$true
$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir\WPFMessagebox.ps1"

#
# $system  =  one of (PROD, TEST, DEV, UPDATE)
#
Function P2V_message($system)
{ # show header

  
   #$conf_dir="$workdir\conf"
   $conf_dir_base="\\somvat202005\PPS_share\P2V_UM_data"

   $conf_dir="$conf_dir_base\conf"
  # $tenantfile="$conf_dir\all_tenants.csv" 

   $conf_dir_msg="$conf_dir_base\startup_message"
   $msg_file="$conf_dir_msg\message.csv"

   #$tenant_sel =import-csv $tenantfile|select system,ServerURL,tenant
   #$t =$tenant_sel |where {$($_.tenant) -like $tenant}

   #$t|format-list
   #if ($tenant_1 ="") {"wrong argument: tenant $tenant does not exist";exit}

   $InfoParams =@{}

   $msg_to_show=import-csv $msg_file  |where { ($($_.app) -like "$system")-or ($($_.app) -like "ALL")}

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
}
#&  ./P2V_menu.ps1 -csvPath "\\somvat202005\PPS_share\P2V_UM_data\conf\P2Vmenu_prod.csv"


#--  end of file --

