-- query BMI and homelessness by index encounter ID (baseline values only)

select enc_info.pat_id
, enc_info.pat_enc_csn_id
, enc_info.enc_date
, bmi
, pat_homeless_type
from sr3452058_table6_enc_info as enc_info
inner join sr3452058_table1_pat_cohort using (pat_id, pat_enc_csn_id)
