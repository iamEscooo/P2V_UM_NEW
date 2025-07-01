#-----------------------------------------------

$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir\P2V_include.ps1"

$output_path = $output_path_base + "\$My_name"

#-------------------------------------------------


#--- start main part
P2V_header -app $My_name -path $My_path
createdir_ifnotexists ($output_path)
 
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
