-- relevant inpatient and outpatient care during FU

select *
from sr3452058_table2_enc_ip_op
-- OBGYN
where upper(provider_specialty) in ('OBSTETRICS & GYNECOLOGY'
                ,'OBSTETRICS & GYNECOLOGY NURSE PRACTITIONER'
                ,'OBSTETRICS GYNECOLOGY, GENERAL'
                ,'GYNECOLOGY, GENERAL'
                ,'GYNECOLOGY, REPRODUCTIVE ENDOCRINOLOGY'
                ,'GYNECOLOGY, URO-GYNECOLOGY'
                ,'GYNECOLOGY, GYNECOLOGIC ONCOLOGY'
                ,'UROLOGY, URO-GYNECOLOGY'
                ,"WOMEN'S HEALTH NURSE PRACTITIONER")
