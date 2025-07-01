update b
		set b.BASE_UNIT = '0.0978112702799513 m'
from
    PLC_UNIT_DEFINITION_BASE b
		inner join PLC_UNIT_DEFINITION d on d.UNIT_DEFINITION_ID =  b.UNIT_DEFINITION_ID
	where
			d.UNIT_NAME like '%metre (gas)%'


