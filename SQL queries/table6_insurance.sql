-- querying insurance types and insurance type mapping

select * 
from sr3452058_table6_insurance;

select distinct insurance_type, payor_name, benefit_plan_name
from sr3452058_table6_insurance