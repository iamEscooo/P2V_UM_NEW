

# import-module "\\somvat202005\PPS_share\P2V_scripts\GITHUB\P2V_module"
#$env:PSModulePath="$($env:PSModulePath);$PSScriptRoot\include"
#import-module "P2V_module.psd1"
import-module "$PSScriptRoot\P2V_include.psd1"  -verbose
import-module "$PSScriptRoot\P2V_dialog_func.psd1"  -verbose 
#import-module P2V_module

pause
#my_init -path "$PSScriptRoot"

ask_continue -title" geht es weiter?" -msg "$My_name long blabla message to check functionality"

"+----+"|out-host
$workdir=$PSScriptRoot
ask_YesNoAll -title" geht es weiter?" -msg "$My_name long blabla message to check functionality"
"+----+"|out-host

#get_AD_user_GUI -title "Apply changes?" -msg "Apply changes to file xyz ?"
"+----+"|out-host

 $my_new_variable|fl
 
"+----DIALOG +"|out-host
P2V_dialog_func -msg  "Hello 2nd module"

$dialog_date
 

#remove-module "P2V_module"
remove-module "P2V_*"