-- query to grab the occupation closest to baseline (that isn't null)

with all_occupn_baseline as (
select occupn.*
, index.enc_date as index_enc_date
, abs(datediff(index.enc_date, occupn.contact_date)) as margin
, row_number() over(partition by occupn.pat_id order by abs(datediff(index.enc_date, occupn.contact_date))) as rwn
from sr3452058_table6_occupation_hx as occupn
left join sr3452058_table1_pat_cohort as index using (pat_id)
where hx_occupn is not null
)
select *
from all_occupn_baseline
where rwn=1
