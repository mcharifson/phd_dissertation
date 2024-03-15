-- query to extract hormonal contraceptive information from diagnosis table

select *
from sr3452058_table3_diagnosis
where icd10 like '%Z30.01%' or icd10 like '%Z30.4%'
