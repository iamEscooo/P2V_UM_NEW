#-----------------------------------------------
param(
  [string]$tenant=""
  )
#-------------------------------------------------

$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir\P2V_include.ps1"

$user=$env:UserDomain+"/"+$env:UserName

#-------------------------------------------------
#  Set config variables
$output_path = $output_path_base + "\$My_name"

#-------------------------------------------------

#--- start main part

P2V_header -app $My_name -path $My_path


$form1 -f "cleaning up output ..."
createdir_ifnotexists ($output_path)


$tenants=select_PS_tenants -multiple $true -all $false

$form1 -f "exporting auditlogs from:"

foreach ($ts in $tenants.keys)
{
      $t=$tenants[$ts]
	  
      $tenantURL      ="$($t.ServerURL)/$($t.tenant)"
      $base64AuthInfo ="$($t.base64AuthInfo)"
	  $API_URL        ="$tenantURL/PlanningSpace/api/v1/auditlogs?pageSize=1000000"
      $out        ="[DONE]" 

	  # write-host "tenantURL      = $tenantURL"
	  # write-host "API_URL        = $API_URL"
	  # write-host "base64AuthInfo = $base64AuthInfo"
	  # $tenant|out-host
      # write-host "$API_URL"
	  # pause
	  
	  $outfile= "$output_path\$($t.tenant)-audit.csv"
	  Delete-ExistingFile -file $outfile
	  
	  $resp=Invoke-RestMethod -Uri $API_URL -Method GET -Headers @{'Authorization' = "Basic $base64AuthInfo"} -outfile $outfile -passthru
	  
	  
      if (!$resp) { $out="[ERROR]: cannot contact $($t.tenant) !"}   
      else        { 
	  
	  
	  #$resp | Export-Csv "$outfile" 
	 }

      $form2_1 -f $($t.tenant), "$out"
	       
}	

$linesep
$form1 -f "[$output_path]"
$linesep
P2V_footer -app $My_name
Read-Host "Press Enter to close the window"
# ----- end of file -----

