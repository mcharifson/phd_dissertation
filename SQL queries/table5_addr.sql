-- query to grab address data but not save any PHI
-- because its over 500000 rows, I split it into two ordering by date and grabbing top and then bottom

select 
pat_id
, geo_addr_id
, eff_start_date
, eff_end_date
, source
, state_fips_2020
, county_fips_2020
, census_tract_code_2020
, full_fips_tract_2020
, full_fips_block_2020
, state_fips_2010
, county_fips_2010
, census_tract_code_2010
, full_fips_tract_2010
, full_fips_block_2010
, accuracy_type
, accuracy_score
, ROW_NUMBER() OVER(ORDER BY 1) AS rownum
from sr3452058_table5_addr
order by rownum
limit 500000
-- offset 5000000




