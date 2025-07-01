

# Example of loading the module from a network share (legacy path)
# import-module "\\somvat202005\PPS_share\P2V_scripts\GITHUB\P2V_module"
import-module "$PSScriptRoot\p2v_mod.psd1"

my_init -path "$PSScriptRoot"

ask_continue -title" geht es weiter?" -msg "$My_name long blabla message to check functionality"

"+----+"|out-host
$workdir=$PSScriptRoot
ask_YesNoAll -title" geht es weiter?" -msg "$My_name long blabla message to check functionality"
"+----+"|out-host

get_AD_user_GUI -title "Apply changes?" -msg "Apply changes to file xyz ?"
"+----+"|out-host

 $my_new_variable|fl
 
 

#remove-module "P2V_module"
remove-module "P2V_mod"