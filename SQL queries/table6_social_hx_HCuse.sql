-- query HC use from HC survey in social history

with hc_use_long as (
select pat_id, pat_enc_csn_id, contact_date, TRUE as HC_status, 'iud' as HC_type
from sr3452058_table6_social_hx
where iud_yn = 'Y'

union all

select pat_id, pat_enc_csn_id, contact_date, TRUE as HC_status, 'pill' as HC_type
from sr3452058_table6_social_hx
where pill_yn = 'Y'

union all

select pat_id, pat_enc_csn_id, contact_date, TRUE as HC_status, 'implant' as HC_type
from sr3452058_table6_social_hx
where implant_yn = 'Y'

union all 

select pat_id, pat_enc_csn_id, contact_date, TRUE as HC_status, 'injection' as HC_type
from sr3452058_table6_social_hx
where injection_yn = 'Y'
) 

select distinct *
from hc_use_long
order by pat_id, contact_date
