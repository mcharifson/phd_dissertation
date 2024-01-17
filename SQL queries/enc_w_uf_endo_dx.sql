-- exploring encounters where UF and Endo are diagnosed

SELECT provider_specialty
, count(*) as n
FROM sr3452058_table2_enc_ip_op
WHERE pat_enc_csn_id IN (
  SELECT DISTINCT pat_enc_csn_id
  FROM sr3452058_table3_diagnosis
  WHERE (icd10 LIKE '%D25%' OR icd10 LIKE '%N80%') AND dx_type = 'Encounter Diagnosis'
)
GROUP BY provider_specialty
ORDER BY count(*) desc