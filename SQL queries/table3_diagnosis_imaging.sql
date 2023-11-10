-- query for abnormal imaging diagnosis

select *
from sr3452058_table3_diagnosis
where 
regexp_like(icd10, 'R93.5|R93.89') and
not regexp_like(lower(dx_name), 'chest|neck|thyroid|lymphatic|carotid|ventricular|gu')