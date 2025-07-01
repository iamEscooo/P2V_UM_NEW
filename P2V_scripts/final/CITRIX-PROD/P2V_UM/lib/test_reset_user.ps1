<#
P2V_set_profiles




#>
param(
  [bool]$debug = $False,
  [bool]$checkonly = $False
)
#-------------------------------------------------

$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir/P2V_include.ps1"

#----- Set config variables
$output_path = $output_path_base + "\$My_name"
$Prof_logfile= $output_path + "\profiles.log"


#-------------------------------------------------
P2V_header -app $My_name -path $My_path 
createdir_ifnotexists($output_path)

#-------------------------------------------------
#P2V_layout 

$tenants= select_PS_tenants -multiple $false

foreach ($ts in $tenants.keys)
{
   $t=$tenants[$ts]
   $tenant=$t.tenant
   $linesep
   $form1 -f "     >>> $tenant <<<"
   $tenantURL  ="$($t.ServerURL)/$($t.tenant)"
   $base64AuthInfo = "$($t.base64AuthInfo)"

   $API_URL   ="$tenantURL/PlanningSpace/api/v1/workgroups?include=users"
   $method    ="GET"
   $form1 -f  "API: $API_URL   $method"
   $body      =""

   $result = Invoke-RestMethod -Uri $API_URL -Method $method -Headers @{'Authorization' = "Basic $base64AuthInfo"} -ContentType "application/json"
   #$result|select id,name,users|format-table|out-host
   foreach ($r in $result|select id,name,users)
   {
    $form1 -f "$($r.id)  : $($r.name)"
	
	$r_c| SELECT -exp $_ |% { $($_.keys)|out-host}
	
	$hash = @{}
    $r.users | Get-Member -MemberType Properties | select -exp "Name" | % { $hash[$_] = ($r.users | SELECT -exp $_) }
	$hash.keys|% {$form2 -f $hash["$_"].id,$hash["$_"].name }
	
	"+--+"
	
	#|% { $($r[$_].Values) }|out-host
   }
   
   
   pause
   $linesep
    $API_URL   ="$tenantURL/PlanningSpace/api/v1/users?include=userWorkgroups"
   $method    ="GET"
   $form1 -f  "API: $API_URL   $method"
   $body      =""

   $result = Invoke-RestMethod -Uri $API_URL -Method $method -Headers @{'Authorization' = "Basic $base64AuthInfo"} -ContentType "application/json"
   #$result|select id,name,users|format-table|out-host
   foreach ($r in $result|select id,logonID,displayname,userworkgroups)
   {
    $form1 -f "$($r.id)  : $($r.logonID) / $($r.displayname)"
	
	$r_c| SELECT -exp $_ |% { $($_.keys)|out-host}
	
	$hash = @{}
    $r.userworkgroups | Get-Member -MemberType Properties | select -exp "Name" | % { $hash[$_] = ($r.userworkgroups | SELECT -exp $_) }
	$hash.keys|% {$form2 -f $hash["$_"].id,$hash["$_"].name }
	
	"+--+"
	
	#|% { $($r[$_].Values) }|out-host
   }
   
   
   pause
   $linesep
   
   $API_URL   = "$($tenantUrl)/planningspace/api/v1/workgroups/bulk"
   $method    = "PATCH"
   $form1 -f    "API: $API_URL   $method"
   $body      = ""
   $uid="152"  # Astl
   $gid_1="9"    # data.Austria
   $gid_2="8"    # data.corporate
   
   
   
   $form1 -f "Test1  remove user from group"
   $form1 -f  "API: $API_URL   $method"
   $body    ='{ "'+$gid_1+'": [ { "op": "remove","path": "/users/'+$uid+'", "value": "" }] }'
   $body
   
   $result = Invoke-RestMethod -Uri $API_URL -Method $method -Headers @{'Authorization' = "Basic $base64AuthInfo"} -body $body -ContentType "application/json"
   $result
    
	
   




}
P2V_footer -app $My_name




