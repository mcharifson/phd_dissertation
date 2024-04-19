-- query for ART use codes in table3_diagnosis

select *
from sr3452058_table3_diagnosis
where icd10 like '%O09.81%' 
  or icd10 like '%Z31.83%' 
  or lower(dx_name) like '%assisted reproductive%'
  or lower(dx_name) like '%ivf%'
  or lower(dx_name) like '%fertilization%'