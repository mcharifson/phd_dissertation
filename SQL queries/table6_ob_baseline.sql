-- query OB info at baseline, joining as close to baseline (within 30 days) as possible
-- double check the coverage on this margin if not 100% consider expanding to 60 days

with all_ob_baseline as (
select ob.*
, index.enc_date as index_enc_date
, abs(datediff(index.enc_date, ob.contact_date)) as margin
, row_number() over(partition by ob.pat_id order by abs(datediff(index.enc_date, ob.contact_date))) as rwn
from sr3452058_table6_ob as ob
left join sr3452058_table1_pat_cohort as index using (pat_id)
)
select *
from all_ob_baseline
where rwn=1 
