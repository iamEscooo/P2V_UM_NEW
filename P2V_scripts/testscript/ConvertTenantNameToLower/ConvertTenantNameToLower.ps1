$SQLServer = "<SERVERNAME>"
$db = "<DATABASE NAME>"
$updatedata = "UPDATE [IPS].[TenantInfo] SET [TenantName] = LOWER([TenantName])"
Invoke-Sqlcmd -ServerInstance $SQLServer -Database $db -Query $updatedata