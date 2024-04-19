SELECT *
FROM sr3452058_table3_diagnosis
WHERE icd10 LIKE '%D25%' OR 
      icd10 LIKE '%N80%' OR
      (icd10 in ('D21.9', 'O34.10', 'O34.11', 'O34.12', 'O34.13', 'IMO0001', 'N93.9', 'D28.1', 'O46.8X1', 'Z86.0.18')) and 
                regexp_like(lower(dx_name), 'fibroid|leiomyoma|uterine myoma|uterine fibromyoma')) OR
      ((icd10 in ('Z87.42', 'N97.2', 'IMO0002') or icd10 is null) and lower(dx_name) like '%endometriosis%')

