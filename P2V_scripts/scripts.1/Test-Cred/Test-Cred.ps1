function Test-Cred {
           
    [CmdletBinding()]
    [OutputType([String])] 
       
    Param ( 
        [Parameter( 
            Mandatory = $false, 
            ValueFromPipeLine = $true, 
            ValueFromPipelineByPropertyName = $true
        )] 
        [Alias( 
            'PSCredential'
        )] 
        [ValidateNotNull()] 
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()] 
        $Credentials
    )
    $Domain = $null
    $Root = $null
    $Username = $null
    $Password = $null
      
    If($Credentials -eq $null)
    {
        Try
        {
            $Credentials = Get-Credential "domain\$env:username" -ErrorAction Stop
        }
        Catch
        {
            $ErrorMsg = $_.Exception.Message
            Write-Warning "Failed to validate credentials: $ErrorMsg "
            Pause
            Break
        }
    }
      
    # Checking module
    Try
    {
        # Split username and password
        $Username = $credentials.username
        $Password = $credentials.GetNetworkCredential().password
  
        # Get Domain
        $Root = "LDAP://" + ([ADSI]'').distinguishedName
        $Domain = New-Object System.DirectoryServices.DirectoryEntry($Root,$UserName,$Password)
    }
    Catch
    {
        $_.Exception.Message
        Continue
    }
  
    If(!$domain)
    {
        Write-Warning "Something went wrong"
    }
    Else
    {
        If ($domain.name -ne $null)
        {
            return "Authenticated"
        }
        Else
        {
            return "Not authenticated"
        }
    }
}


$cred= Get-Credential
fl $cred
Test-Cred $cred
write-output "> DEVELOPMENT <"
$resp=Invoke-RestMethod -Uri "https://tsomvat502898.ww.omv.com/admin/api/TenantSettings" -Credential $Cred
$resp.tenants|select tenantName,isEnabled|ft
write-output "> TEST        <"
$resp=Invoke-RestMethod -Uri "https://ips-test.ww.omv.com/admin/api/TenantSettings" -Credential $Cred
$resp.tenants|select tenantName,isEnabled|ft
write-output "> UPDATE      <"
$resp=Invoke-RestMethod -Uri "https://ips-update.ww.omv.com/admin/api/TenantSettings" -Credential $Cred
$resp.tenants|select tenantName,isEnabled|ft
write-output "> PRODUCTION  <"
$resp=Invoke-RestMethod -Uri "https://ips-prod.ww.omv.com/admin/api/TenantSettings" -Credential $Cred
$resp.tenants|select tenantName,isEnabled|ft
