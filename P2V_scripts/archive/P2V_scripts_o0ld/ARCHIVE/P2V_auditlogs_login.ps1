#-----------------------------------------------
param(
  [string]$tenant=""
  )
#-------------------------------------------------
$My_name=$($MyInvocation.MyCommand.Name)
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
$workdir=$My_Path

If (!$tenant)
{
" 
missing argument:  -tenant 

correct usage:  $My_name  -tenant xxx
     xxx ... existing tenant
"
exit
}

. "$workdir/P2V_include.ps1"

#-------------------------------------------------
#  Set config variables
$scriptname=$($MyInvocation.MyCommand.Name)

$config_path = $workdir     + "\config"
$adgroupfile = $config_path + "\all_adgroups.csv"
$tenantfile  = $config_path + "\all_tenants.csv"
$output_path = $workdir     + "\output\PS-audits"

#-------------------------------------------------

#--- start main part
cls
P2V_header -app $My_name -path $My_path 

$all_systems = @()
$all_systems =import-csv $tenantfile 

$form1 -f "exporting auditlogs from:"


foreach ($i in $all_systems)
{

      $form1 -f ">>>--- $($i.tenant) ---<<<"
	  $authURL    ="$($i.ServerURL)/identity/connect/token"
      $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $i.name, $i.API)))
      $tenantURL  ="$($i.ServerURL)/$($i.tenant)"
          
      

	  $resp=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/auditlogs" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
      if (!$resp) { $out="[ERROR]: cannot contact $($i.tenant) !"}   
      else        { 
	    $resp | Export-Csv "$output_path\$($i.tenant)-audit.csv" 
	    $logins= $resp |where-object {$($_.entityTypeName) -eq "user"}
	    $logins |select id,timestamp,machineName,userName,entityName,comment |format-table
      }
      
	       
}	

$linesep
$form1 -f "[$output_path]"
$linesep
# ----- end of file -----
