-- query to extract hormonal contraceptive information from diagnosis table

select *
from sr3452058_table3_diagnosis
where not regexp_like(lower(dx_name), 'history|hx|h/o|condoms|morning after|basal body temp|emergency|vasectomy|postcoital|rhythm|never')
    and (icd10 like '%Z30.01%' 
    or icd10 like '%Z30.4%'
    or dx_name like '%contracepti%')
