-- query for symptom codes from table3_diagnosis
-- these codes will be explored in patients with confirmed UF and Endo diagnosis to identify
-- their first LIKELY recorded symptom of UF and Endo
-- we will also use these to explore potential false negative diagnoses 
-- (patients with high symptom burden and no differential diagnosis)

select *,
ROW_NUMBER() OVER(ORDER BY 1) AS rownum
from sr3452058_table3_diagnosis
where 
lower(dx_name) not like '%pregnancy%' AND
-- menstrual symptoms
(regexp_like(icd10, 'N94.4|N94.5|N94.6|N93.8|N93.9|N92.0|N92.1|N94.0|N83.0|N83.2|R10.2') OR
-- all other symptoms
regexp_like(icd10, 'F52.6|N94.1|N97.9|N93.0|D50.0|N39.3|N32.9|K95.00|R19.7|M54.5|N73.9'))
ORDER BY rownum
LIMIT 500000
--OFFSET 500000