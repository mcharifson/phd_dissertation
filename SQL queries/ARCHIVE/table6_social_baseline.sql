-- all social history information at baseline

with all_social_baseline as (
select social.*
, index.enc_date as index_enc_date
, abs(datediff(index.enc_date, social.contact_date)) as margin
, row_number() over(partition by social.pat_id order by abs(datediff(index.enc_date, social.contact_date))) as rwn
from sr3452058_table6_social_hx as social
left join sr3452058_table1_pat_cohort as index using (pat_id)
)
select pat_id
, pat_enc_csn_id
, contact_date
, iud_yn
, pill_yn
, surgical_yn
, implant_yn
, injection_yn
, index_enc_date
, margin
from all_social_baseline
where rwn=1;