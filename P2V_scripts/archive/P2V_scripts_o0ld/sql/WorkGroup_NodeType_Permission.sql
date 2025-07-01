SELECT WorkgroupName  AS [Workgroup Name], W.Description AS [Workgroup Description]
, ApplicationName as [Entity Type Application]
, nt.TypeName AS [Entity Name]
, CASE WHEN(MAX(Permission & 1) + MAX(Permission & 32)) = 1 THEN 'Allow' WHEN    (MAX(Permission & 1) + MAX(Permission & 32))  = 32 THEN 'Denied' ELSE NULL END as [Read],
  CASE WHEN(MAX(Permission & 2) + MAX(Permission & 64)) = 2 THEN 'Allow' WHEN    (MAX(Permission & 2) + MAX(Permission & 64))  = 64 THEN 'Denied' ELSE NULL END as [Create],
  CASE WHEN(MAX(Permission & 4) + MAX(Permission & 128)) = 4 THEN 'Allow' WHEN   (MAX(Permission & 4) + MAX(Permission & 128))  = 128 THEN 'Denied' ELSE NULL END as [Update],
  CASE WHEN(MAX(Permission & 8) + MAX(Permission & 256)) = 8 THEN 'Allow' WHEN   (MAX(Permission & 8) + MAX(Permission & 256))  = 256 THEN 'Denied' ELSE NULL END as [Delete],
  CASE WHEN(MAX(Permission & 16) + MAX(Permission & 512)) = 16 THEN 'Allow' WHEN (MAX(Permission & 16) + MAX(Permission & 512))  = 512 THEN 'Denied' ELSE NULL END as  [Assign]
FROM COMMON.EntityWorkGroupPermission EWG
INNER JOIN COMMON.PermissionContext EWP on EWG.PermissionContextId = EWP.PermissionContextId
INNER JOIN COMMON.[Workgroup] W ON EWG.WorkgroupId = W.WorkgroupId
INNER join DATAFLOW.NodeType NT ON EWG.EntityTypeId = NT.NodeTypeId
 WHERE ApplicationName = 'PlanningSpace Dataflow' 
 GROUP BY WorkgroupName, [Description], ApplicationName, NT.TypeName
