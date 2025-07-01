#-----------------------------------------------
#   export  auditlogs for all TENANTS
#
#
#-----------------------------------------------

#-------------
# Web-API
# set Web-API connectivity

$tenantfile="\\somvat202005\PPS_Share\Userlists\all_tenants.csv"
$all_systems = @()

$all_systems =import-csv $tenantfile  #| where-object {$_.tenant -eq "PPS_TEST" }


#-------------
#systemsettings
#  Set path for temp userlists
$output_path="\\somvat202005\PPS_Share\Userlists\PS-users\"


#-------------
# start
cls
$date= Get-Date
Write-Host "
+---------------------------------------------------------+
|  exporting users and groups from AUCERNA Planningspace  |
|                                                         |
|  started at $date                         |
+---------------------------------------------------------+

 Contacting tenants:
"


foreach ($i in $all_systems){

    $out= " > {0,-15}: " -f $i.tenant
	
    $authURL="$($i.ServerURL)/identity/connect/token"
    $tenantURL= "$($i.ServerURL)/$($i.tenant)/$($i.Resource)"
    
    # start authentication 
    #write-host $authURL
    #write-host $tenantURL
    write-host "$out"

    $authResponse = Invoke-RestMethod -Method Post -Uri $authURL -headers @{'Content-Type'= 'application/x-www-form-urlencoded'} -body "grant_type=password&username=$($i.usern)&password=$($i.passw)&scope=planningspace&client_id=$($i.tenant)+resource_owner&client_secret="

    # get users   
    
    $resp=Invoke-RestMethod -Uri "$tenantURL/api/v1/users" -header @{'Authorization' = 'Bearer ' + $authResponse.access_token}
    #$resp | convertto-Csv   #  Export-Csv "$output_path$($i.tenant)-users.csv" 
    $locked_resp=$null
    $locked_resp=$resp|where-object {$_.isAccountLocked -eq "True" }
    #$locked_resp=$resp|where-object {$_.displayName -like "*Stancu*" } # testing purposes
    $locked_resp   |select id,displayName,logOnId,authenticationMethod ,domain,isAccountLocked,accountLockedDate, isDeactivated, userMustChangePassword |Format-table
    #$locked_resp   |Format-table
    #$locked_resp |select id,displayName,logOnId,isAccountLocked| Export-Csv "$output_path$($i.tenant)-lockedusers.csv" 
    
    $out= " > {0,-15}: " -f $i.tenant
    $out +="[{0,3}]/" -f $locked_resp.count
    $out += "[{0,3}] users,"  -f $resp.count
    write-host -NoNewline $out
    
    # get workgroups
    
    $resp=Invoke-RestMethod -Uri "$tenantURL/api/v1/workgroups" -header @{'Authorization' = 'Bearer ' + $authResponse.access_token}
    # $resp | Export-Csv "$output_path$($i.tenant)-groups.csv" 
    $out="[{0,3}] groups " -f $resp.count
    write-host "$out [done]"
    }

$date= Get-Date

write-host " 
 data storing in 
 $output_path
+---------------------------------------------------------+
|   finished at $date                       |
+---------------------------------------------------------+"

# ----- end of file -----

