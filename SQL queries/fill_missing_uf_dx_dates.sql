-- query to fill in dx_date for medical history UF dx where dx_date is missing 
-- using encounter information 
-- (NOTE: cannot fill with encounters prior to 8/1/2016 because encounters are only grabbed after that date)

with missing_dx_dates as (
    select *
    from sr3452058_table3_diagnosis
    where (icd10 like '%D25%' or icd10 like '%N80%') and dx_date is null
)

select distinct dx.*
, coalesce(enc.enc_date, ed.enc_date) as dx_date_filled
from missing_dx_dates as dx
left join sr3452058_table2_enc_ip_op as enc using (pat_id, pat_enc_csn_id)
left join sr3452058_table2_enc_ed as ed using (pat_id, pat_enc_csn_id)
