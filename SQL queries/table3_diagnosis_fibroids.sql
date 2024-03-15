-- SQL to pull fibroid diagnoses

select *
from sr3452058_table3_diagnosis
where icd10 like '%D21.9%' and regexp_like(lower(dx_name), 'fibroid|leiomyoma')
