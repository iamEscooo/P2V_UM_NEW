-- This script created for new nodes
--
select * from DATAFLOW.NodeType

insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('GAS Project', 'GAS Project', 'Pipeline', 28, 13)