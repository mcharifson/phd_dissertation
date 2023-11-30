-- all social history information at baseline

select social.*
from sr3452058_table6_social_hx as social
left join sr3452058_table1_pat_cohort as index using (pat_id)
where abs(datediff(index.enc_date, social.contact_date)) < 30;
