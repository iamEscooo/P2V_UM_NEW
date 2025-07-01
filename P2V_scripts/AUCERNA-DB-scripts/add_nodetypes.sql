-- This script created for new nodes
--

select * from DATAFLOW.NodeType


update DATAFLOW.NodeType
set TypeDescription = 'Project RUS (PRMS)'
where TypeName = 'Project RUS (PRMS)'


insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('Project MYS (PRMS)', 'Project MYS (PRMS)', 'Discovery', 28, 11)



insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('Project AUS (PRMS)', 'Project AUS (PRMS)', 'Discovery', 28, 11)



insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('Project NZL (PRMS)', 'Project NZL (PRMS)', 'Discovery', 28, 11)



insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('Project BGR (PRMS)', 'Project BGR (PRMS)', 'Discovery', 28, 11)



insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('Project ROU (PRMS)', 'Project ROU (PRMS)', 'Discovery', 28, 11)



insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('Project GEO (PRMS)', 'Project GEO (PRMS)', 'Discovery', 28, 11)



insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('Project MEX (PRMS)', 'Project MEX (PRMS)', 'Discovery', 28, 11)

