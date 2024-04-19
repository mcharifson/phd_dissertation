-- SQL code to extract COVID-19 LTFU which should be a binary yes/no did this patients have any IN PERSON encounters
-- between March 15, 2020-July 1, 2021 [dates of closing and reopening of NYC] but then seen again)
-- regardless of provider type (not restricted to relevant encounters, but excluding telemedicine encounters

-- inpatient
SELECT 
pat_id
, count(*) as num_enc
, countif(regexp_like(lower(adt_service), 'general|obstetrics|gynecology|urology|endocrinology|emergency|family|radiology') and
    adt_service not like '%Neurology%') as num_relevant_enc
FROM sr3452058_table2_enc_ip_op
WHERE enc_date > '2020-03-15' and enc_date < '2021-07-01' and enc_type != 'Telemedicine'
group by pat_id

-- outpatient
select 
pat_id
, count(*) as num_enc
, countif(upper(longest_provider_specialty) in ('ACUTE CARE NURSE PRACTITIONER','ADULT HEALTH NURSE PRACTITIONER','GENERAL PRACTICE','GYNECOLOGY, GENERAL'
    ,'GYNECOLOGY, REPRODUCTIVE ENDOCRINOLOGY','GYNECOLOGY, URO-GYNECOLOGY','MEDICINE, ADULT','MEDICINE, ENDOCRINOLOGY','MEDICINE, ENDOCRINOLOGY, DIABETES, OBESITY, METABOLISM'
    ,'MEDICINE, FAMILY MEDICINE','MEDICINE, INTERNAL MEDICINE','NURSE PRACTITIONER','OBSTETRICS & GYNECOLOGY','OBSTETRICS & GYNECOLOGY NURSE PRACTITIONER'
    ,'OBSTETRICS GYNECOLOGY, GENERAL','OBSTETRICS, GENERAL','OBSTETRICS, MATERNAL FETAL MEDICINE','UROLOGY, URO-GYNECOLOGY',"WOMEN'S HEALTH NURSE PRACTITIONER"
    ,'EMERGENCY MEDICINE, ADULT','EMERGENCY MEDICINE, GENERAL','EMERGENCY MEDICINE, PEDIATRICS','FAMILY NURSE PRACTITIONER','GYNECOLOGY, GYNECOLOGIC ONCOLOGY'
    ,'PEDIATRIC ENDOCRINOLOGY','PEDIATRIC NURSE PRACTITIONER' ,'PEDIATRICS, ADOLESCENT MEDICINE','PEDIATRICS, GENERAL','PHYSICIAN ASSISTANT'
    ,'PHYSICIAN ASSISTANT, MEDICAL','REGISTERED NURSE','URGENT CARE')) as num_relevant_enc
from sr3452058_table2_enc_ed
where enc_date > '2020-03-15' and enc_date < '2021-07-01'

-- ED
select *
from sr3452058_table2_enc_ed

