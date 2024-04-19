-- relevant inpatient and outpatient care during FU

select *
from sr3452058_table2_enc_ip_op
-- general care from MDs
where upper(provider_specialty) in ('GENERAL PRACTICE'
                  ,'MEDICINE, ADULT'
                  ,'MEDICINE, INTERNAL MEDICINE')
