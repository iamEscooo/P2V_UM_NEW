

$source = "\\somvat202005\PPS_share\P2V_Script-setup(new)\local\P2V"
$dest   = "c:"

# remove-item "$dest\P2V_UM\" -Recurse -Force
# copy-item "$source\P2V_UM\"     -destination "$dest\P2V_UM\"    -recurse  -force


remove-item "$dest\P2V_start\" -Recurse -Force
copy-item "$source\P2V_start\"  -destination "$dest\P2V_start\" -recurse  -force


#pause