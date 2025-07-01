-- This scripts add the additional node types
-- Gael Carlier 20-04-2021

select * from DATAFLOW.NodeType

-- update DATAFLOW.NodeType
-- set TypeDescription = 'Project RUS (PRMS)'
-- where TypeName = 'Project RUS (PRMS)'

-- Project BD_PSC_1 (PRMS) , Project BD_PSC_2 (PRMS), Project BD_RT_1 (PRMS), Project BD_RT_2 (PRMS)
select * from DATAFLOW.NodeType

insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('XProj BD_PSC_ANY (PRMS)', 'XProj BD_PSC_ANY (PRMS)', 'Discovery', 28, 11)

insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('XProj BD_PSC_EUR (PRMS)', 'XProj BD_PSC_EUR (PRMS)', 'Discovery', 28, 11)

insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('XProj BD_PSC_USD (PRMS)', 'XProj BD_PSC_USD (PRMS)', 'Discovery', 28, 11)

insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('XProj BD_RT_ANY (PRMS)', 'XProj BD_RT_ANY (PRMS)', 'Discovery', 28, 11)

insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('XProj BD_RT_EUR (PRMS)', 'XProj BD_RT_EUR (PRMS)', 'Discovery', 28, 11)

insert into DATAFLOW.NodeType (TypeName, TypeDescription, ImageKey, ParentNodeTypeId, DefaultTemplateId)
values ('XProj BD_RT_USD (PRMS)', 'XProj BD_RT_USD (PRMS)', 'Discovery', 28, 11)

