-- SQL script to identify any codes related to pregnancy throughout diagnosis table

SELECT *
from sr3452058_table3_diagnosis
where regexp_like(icd10, 'O80|O82')
  or lower(dx_name) like '%delivery%'
  or lower(dx_name) like '%pregnancy%'