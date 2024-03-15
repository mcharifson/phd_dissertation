-- pull baseline insurance for index encounters

with insur_map as (
select distinct insurance_type, payor_name, benefit_plan_name
from sr3452058_table6_insurance
),

ip_op as (
select
ipop.pat_id
, ipop.pat_enc_csn_id 
, ipop.enc_date
, case when payor_name  = 'NULL' then null else payor_name 
end as payor_name
, case when benefit_plan_name  = 'NULL' then null else benefit_plan_name 
end as benefit_plan_name
from sr3452058_table2_enc_ip_op as ipop
inner join sr3452058_table1_pat_cohort using (pat_id, pat_enc_csn_id, enc_date)
)

select 
distinct ip_op.*, insurance_type 
from ip_op
left join insur_map using (payor_name, benefit_plan_name)

