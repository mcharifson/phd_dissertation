-- identify pregnancies during follow-up period

with dx_codes as (
select pat_id, dx_date as event_date, dx_name as event
from sr3452058_table3_diagnosis
where 
    -- during follow-up
    dx_date > '2016-08-01' and 
    dx_date < '2023-08-01' and 
    -- no historical codes
    not regexp_like(lower(dx_name), 'history|hx|h/o') and 
    not regexp_like(dx_type, 'Medical History') and
    -- Codes for delivery
    (regexp_like(icd10, 'O80|O82|Z37|Z38|Z3A|Z34') or
    regexp_like(lower(dx_name), 'svd|cesarean|c-section|csection|livebirth|live birth|liveborn|vaginal birth|vaginal delivery'))

),

surgery_codes as (
select pat_id, surgery_date as event_date, procedure_name as event
from sr3452058_table4_surgical_procedure
where 
    -- during follow-up
    surgery_date > '2016-08-01' and 
    surgery_date < '2023-08-01' and 
    -- cesarean
    regexp_like(lower(procedure_name), 'cesarean')
),

all_preg_rows as (
select * from dx_codes
union all
select * from surgery_codes
)

select ob.*
from sr3452058_table6_ob as ob
inner join all_preg_rows as preg on preg.pat_id = ob.pat_id and preg.event_date = ob.contact_date


