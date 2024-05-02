-- SQL script to record the most common hospital visited by a given patient (at baseline and during follow-up)
-- This is only necessary for outpatient encounters as inpatient, ED, and telemedicine are already clean

-- inpatient
with baseline_site as (
SELECT 
pat_id
, countif(regexp_like(lower(loc_name), 'tisch|kimmel|trinity|nyu langone orthopedic hospital') or 
  regexp_like(lower(dep_external_name), 'tisch|kimmel|trinity|nyu langone orthopedic hospital')) as num_tisch
, countif(regexp_like(lower(loc_name), 'brooklyn') or regexp_like(lower(dep_external_name), 'brooklyn')) as num_brooklyn
, countif(regexp_like(lower(loc_name), 'family health center') or regexp_like(lower(dep_external_name), 'family health center')) as num_FHC
, countif(regexp_like(lower(loc_name), 'long island|winthrop') or regexp_like(lower(dep_external_name), 'long island|winthrop')) as num_long_island
, countif(regexp_like(lower(loc_name), 'telemed|telehealth') or regexp_like(lower(dep_external_name), 'telemed|telehealth')) as num_telemedicine
FROM sr3452058_table2_enc_ip_op
WHERE enc_date >= '2016-08-01' and enc_date <= '2017-12-31' and enc_type = 'Ambulatory'
group by pat_id
),
followup_site as (
SELECT 
pat_id
, countif(regexp_like(lower(loc_name), 'tisch|kimmel|trinity|nyu langone orthopedic hospital') or 
  regexp_like(lower(dep_external_name), 'tisch|kimmel|trinity|nyu langone orthopedic hospital')) as num_tisch
, countif(regexp_like(lower(loc_name), 'brooklyn') or regexp_like(lower(dep_external_name), 'brooklyn')) as num_brooklyn
, countif(regexp_like(lower(loc_name), 'family health center') or regexp_like(lower(dep_external_name), 'family health center')) as num_FHC
, countif(regexp_like(lower(loc_name), 'long island|winthrop') or regexp_like(lower(dep_external_name), 'long island|winthrop')) as num_long_island
, countif(regexp_like(lower(loc_name), 'telemed|telehealth') or regexp_like(lower(dep_external_name), 'telemed|telehealth') or 
  enc_type == 'Telemedicine') as num_telemedicine
FROM sr3452058_table2_enc_ip_op
WHERE enc_date > '2017-12-31' and enc_date <= '2023-08-01' and enc_type = 'Ambulatory'
group by pat_id
)
select *
from baseline_site
full join followup_site on baseline_site.pat_id = followup_site.pat_id

with rename_loc as (
SELECT 
pat_id
, case 
    when regexp_like(lower(loc_name), 'tisch|kimmel|trinity|nyu langone orthopedic hospital') 
      or regexp_like(lower(dep_external_name), 'tisch|kimmel|trinity|nyu langone orthopedic hospital') 
    then 'TISCH HOSPITAL'
    when regexp_like(lower(loc_name), 'brooklyn') or regexp_like(lower(dep_external_name), 'brooklyn') then 'NYU LANGONE BROOKLYN'
    when regexp_like(lower(loc_name), 'family health center') or regexp_like(lower(dep_external_name), 'family health center') then 'FAMILY HEALTH CENTERS'
    when regexp_like(lower(loc_name), 'long island|winthrop') or regexp_like(lower(dep_external_name), 'long island|winthrop') then 'NYU LANGONE HOSPITAL - LONG ISLAND'
    when regexp_like(lower(loc_name), 'telemed|telehealth') or regexp_like(lower(dep_external_name), 'telemed|telehealth') then 'TELEMEDICINE'
  end as new_loc_name
FROM sr3452058_table2_enc_ip_op
WHERE enc_date >= '2016-08-01' and enc_date <= '2017-12-31'
),
site_counts as (
SELECT 
pat_id
, new_loc_name
, count(*) as n_encounters
from rename_loc
where new_loc_name is not null
group by pat_id, new_loc_name
)
select count(distinct pat_id)
from site_counts
--qualify row_number() over (parition by pat_id, loc_name order by n_encounters asc)=1

