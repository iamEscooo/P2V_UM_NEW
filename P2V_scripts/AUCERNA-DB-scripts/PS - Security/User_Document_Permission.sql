SELECT UserName AS Name
, LoginId AS [Login ID]
,CASE AuthenticationMethod WHEN 0 THEN 'Local' WHEN 1 THEN 'Windows Active Directory' WHEN 2 THEN 'SAML2' END AS [Authentication Method]
, Domain
, U.Description
, CASE IsDeactivated WHEN 0 THEN 'FALSE' WHEN 1 THEN 'TRUE' END AS [Deactivated]
, v.VersionName AS [Version Name]
, DATAFLOW.FN_FullHierarchyPath( dv.documentversionid) as [Document Full Path]
, DV.DocumentName AS [Document Name]
, NT.TypeName AS [Entity Name]
, CASE WHEN(MAX(Permission & 1) + MAX(Permission & 32)) = 1 THEN 'Allow' WHEN    (MAX(Permission & 1) + MAX(Permission & 32))  = 32 THEN 'Denied' ELSE NULL END as [Read],
  CASE WHEN(MAX(Permission & 4) + MAX(Permission & 128)) = 4 THEN 'Allow' WHEN   (MAX(Permission & 4) + MAX(Permission & 128))  = 128 THEN 'Denied' ELSE NULL END as [Update],
  CASE WHEN(MAX(Permission & 8) + MAX(Permission & 256)) = 8 THEN 'Allow' WHEN   (MAX(Permission & 8) + MAX(Permission & 256))  = 256 THEN 'Denied' ELSE NULL END as [Delete],
  CASE WHEN(MAX(Permission & 16) + MAX(Permission & 512)) = 16 THEN 'Allow' WHEN (MAX(Permission & 16) + MAX(Permission & 512))  = 512 THEN 'Denied' ELSE NULL END as  [Assign]
FROM COMMON.InstanceUserPermission IUP
INNER JOIN COMMON.PermissionContext EWP on IUP.PermissionContextId = EWP.PermissionContextId
INNER JOIN COMMON.[User] U ON IUP.UserId = U.UserId
INNER JOIN DATAFLOW.DocumentVersion DV on IUP.instanceId = dv.DocumentVersionId 
INNER JOIN DATAFLOW.[Version] V on DV.versionid = V.versionid 
INNER JOIN DATAFLOW.[NodeType] NT on DV.entitytypeid = NT.nodetypeid 
 WHERE ApplicationName = 'PlanningSpace Dataflow'
 GROUP BY UserName, U.Description , v.versionname, documentname, documentversionid,nt.TypeName, LoginId, AuthenticationMethod, Domain, IsDeactivated 
