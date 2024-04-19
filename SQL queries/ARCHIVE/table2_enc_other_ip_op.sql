-- relevant care from inpatient and outpatient for other specialties

select *
from sr3452058_table2_enc_ip_op
where upper(provider_specialty) in (
                -- ob care
                'OBSTETRICS, GENERAL'
                ,'OBSTETRICS, MATERNAL FETAL MEDICINE'
                -- endocrine care
                ,'MEDICINE, ENDOCRINOLOGY'
                ,'MEDICINE, ENDOCRINOLOGY, DIABETES, OBESITY, METABOLISM'
                -- emed
                ,'EMERGENCY MEDICINE, ADULT'
                ,'EMERGENCY MEDICINE, GENERAL'
                ,'EMERGENCY MEDICINE, PEDIATRICS'
                ,'URGENT CARE'
                -- general non-MD
                ,'ACUTE CARE NURSE PRACTITIONER'
                ,'ADULT HEALTH NURSE PRACTITIONER'
                ,'NURSE PRACTITIONER'
                ,'PHYSICIAN ASSISTANT'
                ,'PHYSICIAN ASSISTANT, MEDICAL'
                ,'REGISTERED NURSE'
                -- pediatric and family med
                ,'MEDICINE, FAMILY MEDICINE'
                ,'FAMILY NURSE PRACTITIONER'
                ,'PEDIATRIC ENDOCRINOLOGY'
                ,'PEDIATRIC NURSE PRACTITIONER' 
                ,'PEDIATRICS, ADOLESCENT MEDICINE'
                ,'PEDIATRICS, GENERAL')