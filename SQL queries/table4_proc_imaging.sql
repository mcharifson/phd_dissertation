-- query for imaging procedures for UF and Endo

select *
from sr3452058_table4_procedure_order
where (procedure_code != 'SUP273' and order_status = 'Completed') and

((procedure_code_type = 'CPT(R)' and
procedure_code in ('76856', '76830', '58555', '72197', '72195', '74177', '74176', 
'72192', '72193', '58340', '74740', '58340', '76381')) or

regexp_like(lower(procedure_name), 'hysterosalpingography|sonohysterography|hysteroscopy') or

(regexp_like(lower(procedure_name), 'transabdominal|transvaginal|pelvi') 
and regexp_like(lower(procedure_name), 'us |ultrasound')) or

(regexp_like(lower(procedure_name), 'pelvi') and regexp_like(lower(procedure_name), 'ct |mri')))
