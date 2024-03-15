-- query pat cohort table 1 without DOB

select
pat_mrn_id
, pat_id
, death_date
, pat_living_stat_c
, age_20160801
, gender
, pat_enc_csn_id
, enc_date
, provider_specialty
from sr3452058_table1_pat_cohort
