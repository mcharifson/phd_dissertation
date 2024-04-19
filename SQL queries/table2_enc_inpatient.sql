-- relevant inpatient hospital encounters 

select *
from sr3452058_table2_enc_ip_op
where regexp_like(lower(adt_service), 'general|obstetrics|gynecology|urology|endocrinology|emergency|family|radiology') and
    adt_service not like '%Neurology%'
