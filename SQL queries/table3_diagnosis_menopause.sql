-- code for extracting menopause dx codes from table3_diagnosis

select *
from sr3452058_table3_diagnosis
where (icd10 like '%N95%' or icd10 like '%E28.3%' or icd10 like '%E89.41%') and
  (lower(dx_name) not like '%peri%' and lower(dx_name) not like '%bleeding%')