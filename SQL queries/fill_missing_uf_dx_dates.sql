-- query to fill in dx_date for medical history UF dx where dx_date is missing 
-- using encounter information 
-- (NOTE: cannot fill with encounters prior to 8/1/2016 because encounters are only grabbed after that date)

with missing_dx_dates as (
    SELECT *
    FROM sr3452058_table3_diagnosis
    WHERE icd10 LIKE '%D25%' OR 
          icd10 LIKE '%N80%' OR
          (icd10 in ('D21.9', 'O34.10', 'O34.11', 'O34.12', 'O34.13', 'IMO0001', 'N93.9', 'D28.1', 'O46.8X1', 'Z86.018') and 
                regexp_like(lower(dx_name), 'fibroid|leiomyoma|uterine myoma|uterine fibromyoma')) OR
          ((icd10 in ('Z87.42', 'N97.2', 'IMO0002') or icd10 is null) and lower(dx_name) like '%endometriosis%') AND
          dx_date is null
)

select distinct dx.*
, coalesce(enc.enc_date, ed.enc_date) as dx_date_filled
from missing_dx_dates as dx
left join sr3452058_table2_enc_ip_op as enc using (pat_id, pat_enc_csn_id)
left join sr3452058_table2_enc_ed as ed using (pat_id, pat_enc_csn_id)
where coalesce(enc.enc_date, ed.enc_date) is not null
