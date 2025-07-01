$output_path="\\somvat202005\PPS_share\P2V_UM_data\output\serverinfo\"+$($env:COMPUTERNAME)+ ".txt"
Get-ComputerInfo |tee $output_path 