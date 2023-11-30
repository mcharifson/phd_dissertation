-- query to grab address data but not save any PHI

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
from sr3452058_table5_addr




