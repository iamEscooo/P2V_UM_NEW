#-----------------------------------------------
#   export  auditlogs for all TENANTS
#
#
#-----------------------------------------------

#--  check command line arguments
param(
[string]$tenant,
[string]$xkey)


Write-Host "editing $xkey on $tenant"

Out-GridView


#-------------
# Web-API
# set Web-API connectivity

#-- get tenant connectivity config
$tenantfile="\\somvat202005\PPS_Share\Userlists\all_tenants.csv"
$all_systems = @()

$all_systems =import-csv $tenantfile  | where-object {$_.tenant -eq $tenant }

$new_usersfile="\\somvat202005\PPS_Share\Userlists\PS-users\new_users.csv"
$new_users=import-csv $new_usersfile

#$new_users


#-------------
# start

$date= Get-Date
Write-Host "
+---------------------------------------------------------+
|  creating new users for AUCERNA Planningspace           |
|                                                         |
|  started at $date                         |
+---------------------------------------------------------+

 Contacting  tenants:
"


foreach ($i in $all_systems){

    $out= " > {0,-15}: " -f $i.tenant
	#--  authenticate session
    $authURL="$($i.ServerURL)/identity/connect/token"
    $tenantURL= "$($i.ServerURL)/$($i.tenant)/$($i.Resource)"
    
    #--  start authentication 
    write-host -NoNewline "$out"

    $authResponse = Invoke-RestMethod -Method Post -Uri $authURL -headers @{'Content-Type'= 'application/x-www-form-urlencoded'} -body "grant_type=password&username=$($i.usern)&password=$($i.passw)&scope=planningspace&client_id=$($i.tenant)+resource_owner&client_secret="


    #--  get users / filter
    
    $resp=Invoke-RestMethod -Uri "$tenantURL/api/v1/users" -header @{'Authorization' = 'Bearer ' + $authResponse.access_token}
    # $resp | Export-Csv "$output_path$($i.tenant)-users.csv" 
    #$sel_resp=$resp |select id,displayName,logOnId
    #$sel_resp|convertto-csv|format-table
    #write-host "search - $($xkey.ToUpper())  in "
    #write-host "- $($resp.LogOnId).ToUpper()"
    $sel_resp = $resp |where {$($_.logOnId).toupper() -eq $xkey.ToUpper() }
    $out="[{0,3}] users, " -f $resp.count
    write-host  $out
    $sel_resp| select id, displayName, domain, isAccountLocked |ConvertTo-json

      #lock
      $lock1=$sel_resp
      $lock1.LogOnId=$xkey.ToUpper()
      $lock1.isAccountLocked=$true
    write-host "change"
    $lock1| select id, displayName, domain, isAccountLocked |ConvertTo-json
    pause
    exit
    # new users   
    foreach( $u in $new_users ) {
   write-host "adding user: $($u.displayName)"
   $u1=$u|convertto-json

   $resp=Invoke-RestMethod -Method POST -Uri "$tenantURL/api/v1/users" -header @{'Authorization' = 'Bearer ' + $authResponse.access_token} -body "displayName=$u1.displayName&loginID=$u1.loginID;description=$u1.description,authenticationMethod=$u1.authenticationMethod"
    #$resp | Export-Csv "$output_path$($i.tenant)-users.csv" 
    $resp|select displayName, description, comments

   }
   }
    