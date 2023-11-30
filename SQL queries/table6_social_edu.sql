-- !preview conn=DBI::dbConnect(RSQLite::SQLite())

select pat_id
, pat_enc_csn_id
, contact_date
, years_education
, edu_level
from sr3452058_table6_social_hx as social
where social.edu_level is not null or social.years_education is not null
