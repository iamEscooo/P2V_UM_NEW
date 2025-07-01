#-----------------------------------------------
#   update useraccounts  auditlogs for all TENANTS
#
#
#-----------------------------------------------

#-------------
# Web-API
# set Web-API connectivity

$tenantfile="\\somvat202005\PPS_Share\Userlists\all_tenants1.csv"
$all_systems = @()

$all_systems =import-csv $tenantfile


#-------------
#systemsettings
#  Set path for temp userlists
$change1="\\somvat202005\PPS_Share\Userlists\PS-users\usersCHG-1.csv"
$changelog1 = @()
$changelog1 = import-csv $change1

$change2="\\somvat202005\PPS_Share\Userlists\PS-users\usersCHG-2.csv"
$changelog2 = @()
$changelog2 = import-csv $change2

#$changelog1 


#-------------
# start

$date= Get-Date
Write-Host "
+---------------------------------------------------------+
| updating users in AUCERNA Planningspace  |
|                                                         |
|  started at $date                         |
+---------------------------------------------------------+

 Contacting  tenants:
"

$update1 = @()

foreach ($i in $all_systems) {

    $out= " > {0,-15}: " -f $i.tenant
	
    $authURL="$($i.ServerURL)/identity/connect/token"
    $tenantURL= "$($i.ServerURL)/$($i.tenant)/$($i.Resource)"
    
    # start authentication 
    write-host -NoNewline "$out"

    $authResponse = Invoke-RestMethod -Method Post -Uri $authURL -headers @{'Content-Type'= 'application/x-www-form-urlencoded'} -body "grant_type=password&username=$($i.usern)&password=$($i.passw)&scope=planningspace&client_id=$($i.tenant)+resource_owner&client_secret="

    # get users   
 
        $headers = @{'Authorization' = 'Bearer ' + $($authResponse.access_token);'Content-Type'= 'application/json' }
    write-host "contacting $tenantURL"

    foreach( $i1 in  $changelog1) 
       {
       $i1|convertto-json
            write-host "$tenantURL/api/v1/users/$($i1.id)"
    
            #$i1|select id, displayName, domain |convertto-json 
            #Invoke-RestMethod  -Method Get -Uri "$tenantURL/api/v1/users/$($i1.id)" -header $headers |select id, displayName, description|convertto-json
            $i1|select id, displayName, description|convertto-json  
            # 1st try: $update1= @({ "op"= "replace", "path"= "/displayName", "value"= "$($i1.displayName)" },{ "op"= "replace", "path"= "/description", "value"= "$($i1.description)"} )
            $update1= @{ displayName="$($i1.displayName)"; description= "$($i1.description)"}| ConvertTo-Json
            write-host $update1
            

            Invoke-RestMethod -Method Patch -Uri "$tenantURL/api/v1/users/$($i1.id)" -header $headers -body $i1
            #$out="[{0,4}] users, " -f $resp.count
    write-host  "next"
    pause
        }
    
    #write-host  "next""!
    
}


$date= Get-Date

write-host " 
 data storing in 
 $output_path
+---------------------------------------------------------+
|   finished at $date                       |
+---------------------------------------------------------+"

# ----- end of file -----
