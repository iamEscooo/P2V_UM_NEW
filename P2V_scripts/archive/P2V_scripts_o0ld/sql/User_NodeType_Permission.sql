SELECT UserName AS [Name], LoginId AS [Login ID], 
CASE AuthenticationMethod WHEN 0 THEN 'Local' WHEN 1 THEN 'Windows Active Directory' WHEN 2 THEN 'SAML2' END AS [Authentication Method]
, Domain AS [Domain]
, u.[Description] 
, CASE IsDeactivated WHEN 0 THEN 'FALSE' WHEN 1 THEN 'TRUE' END AS [Deactivated]
, ApplicationName as [Entity Type Application]
, nt.TypeName AS [Entity Name]
, CASE WHEN(MAX(Permission & 1) + MAX(Permission & 32)) = 1 THEN 'Allow' WHEN    (MAX(Permission & 1) + MAX(Permission & 32))  = 32 THEN 'Denied' ELSE NULL END as [Read],
  CASE WHEN(MAX(Permission & 2) + MAX(Permission & 64)) = 2 THEN 'Allow' WHEN    (MAX(Permission & 2) + MAX(Permission & 64))  = 64 THEN 'Denied' ELSE NULL END as [Create],
  CASE WHEN(MAX(Permission & 4) + MAX(Permission & 128)) = 4 THEN 'Allow' WHEN   (MAX(Permission & 4) + MAX(Permission & 128))  = 128 THEN 'Denied' ELSE NULL END as [Update],
  CASE WHEN(MAX(Permission & 8) + MAX(Permission & 256)) = 8 THEN 'Allow' WHEN   (MAX(Permission & 8) + MAX(Permission & 256))  = 256 THEN 'Denied' ELSE NULL END as [Delete],
  CASE WHEN(MAX(Permission & 16) + MAX(Permission & 512)) = 16 THEN 'Allow' WHEN (MAX(Permission & 16) + MAX(Permission & 512))  = 512 THEN 'Denied' ELSE NULL END as  [Assign]
FROM COMMON.EntityUserPermission EUP
INNER JOIN COMMON.PermissionContext EWP on EUP.PermissionContextId = EWP.PermissionContextId
INNER JOIN COMMON.[User] U ON EUP.UserId = U.UserId
INNER join DATAFLOW.NodeType NT ON EUP.EntityTypeId = NT.NodeTypeId
 WHERE ApplicationName = 'PlanningSpace Dataflow'
 GROUP BY UserName, [Description], ApplicationName, LoginId, AuthenticationMethod, Domain, IsDeactivated, NT.TypeName
