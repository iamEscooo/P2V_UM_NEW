#-----------------------------------------------

param(
  [string] $workdir   = "\\somvat202005\PPS_Share\P2V_scripts"
   )
#-------------------------------------------------
#  Set config variables
$scriptname=$($MyInvocation.MyCommand.Name)

$config_path = $workdir     + "\config"
$adgroupfile = $config_path + "\all_adgroups.csv"
$tenantfile  = $config_path + "\all_tenants.csv"
$output_path = $workdir     + "\output\PS-audits"

#-------------------------------------------------

#layout
$linesep="+-------------------------------------------------------------------------------+"
$form1=  "|  {0,-71}      |"
$form2=  "|  {0,-10} {1,-60}      |"
$form2_1="|  {0,-35} {1,35}      |"
$form3=  "|  {0,-10} {1,-50} {2,-10}     |"
#         0         1         2         3         4         5         6         7         8

#--- start main part
cls
$linesep
$form2_1 -f "[$scriptname]",(get-date -format "dd/MM/yyyy HH:mm:ss")  
$linesep	 
$all_systems = @()
$all_systems =import-csv $tenantfile 

$form1 -f "exporting auditlogs from:"


foreach ($i in $all_systems)
{

      $out        ="[DONE]"
	  $authURL    ="$($i.ServerURL)/identity/connect/token"
      $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $i.name, $i.API)))
      $tenantURL  ="$($i.ServerURL)/$($i.tenant)"
          
      

	  $resp=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/auditlogs" -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"}
      if (!$resp) { $out="[ERROR]: cannot contact $($i.tenant) !"}   
      else        { $resp | Export-Csv "$output_path\$($i.tenant)-audit.csv" }

      $form2_1 -f $($i.tenant), "$out"
	       
}	

$linesep
$form1 -f "[$output_path]"
$linesep
# ----- end of file -----
