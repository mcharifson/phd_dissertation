-- SQL script to identify any codes related to pregnancy throughout diagnosis table

with dx_codes as (
select pat_id
from sr3452058_table3_diagnosis
where dx_date < '2017-12-31' and
    (regexp_like(icd10, 'O80|O82|Z37|Z38') or
    regexp_like(lower(dx_name), 'svd|cesarean|c-section|csection|livebirth|live birth|liveborn|vaginal birth|vaginal delivery'))
),
surgery_codes as (
select pat_id
from sr3452058_table4_surgical_procedure
where surgery_date < '2017-12-31' and regexp_like(lower(procedure_name), 'cesarean')
),
all_ids as (
select * from dx_codes
union all
select * from surgery_codes
)
select distinct pat_id,
TRUE as prior_delivery
from all_ids



