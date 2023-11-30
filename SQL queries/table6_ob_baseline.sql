-- query OB info at baseline, joining as close to baseline (within 30 days) as possible
-- double check the coverage on this margin if not 100% consider expanding to 60 days

select ob.*
from sr3452058_table6_ob as ob
left join sr3452058_table1_pat_cohort as index using (pat_id)
where abs(datediff(index.enc_date, ob.contact_date)) < 30
