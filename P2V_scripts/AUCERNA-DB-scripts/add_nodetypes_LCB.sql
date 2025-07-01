-- This script created for new nodes
--

select * from DATAFLOW.NodeType


update DATAFLOW.NodeType
set TypeDescription = 'Project RUS (PRMS)'
where TypeName = 'Project RUS (PRMS)'


insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('Project AUT (LCB)', 'Project AUT (LCB)', 'Discovery', 28, 11)



insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('Project DEU (LCB)', 'Project DEU (LCB)', 'Discovery', 28, 11)



insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('Project ROU (LCB)', 'Project ROU (LCB)', 'Discovery', 28, 11)



insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('Project NOR (LCB)', 'Project NOR (LCB)', 'Discovery', 28, 11)



insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('Project NZL (LCB)', 'Project NZL (LCB)', 'Discovery', 28, 11)



insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('Project TUN (LCB)', 'Project TUN (LCB)', 'Discovery', 28, 11)



insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('Project HUN (LCB)', 'Project HUN (LCB)', 'Discovery', 28, 11)

insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('Project CHE (LCB)', 'Project CHE (LCB)', 'Discovery', 28, 11)

insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('Project BGR (LCB)', 'Project BGR (LCB)', 'Discovery', 28, 11)

insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('Project Default EUR (LCB)', 'Project Default EUR (LCB)', 'Discovery', 28, 11)


insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('Project Default USD (LCB)', 'Project Default USD (LCB)', 'Discovery', 28, 11)
