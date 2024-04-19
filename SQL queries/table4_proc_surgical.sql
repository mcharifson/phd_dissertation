-- query for procedure orders related to UF and Endo Dx

select *
from sr3452058_table4_procedure_order
where order_status = 'Completed' and
    -- procedures based on code
    (procedure_code in ('1962', '38589', '58150', '58180', '58210', '58260','58541', '58542', '58544',
    '58550', '58553', '58570', '58572', '58573', 'SHX1221', 'SHX1223', 'SHX1926', 'SHX1934', 'SHX209',
    'SHX210', 'SHX21050', 'SHX2362', 'SHX2548', 'SHX81', 'SHX82', 'SUR292', 'SUR658', 'SUR661', 
    'SUR797', 'SUR800', '58925', 'SHX85') or
    -- surgeries based on name
    regexp_like(lower(procedure_name), 'hysterectomy|oophorectomy|salpingectomy|myomectomy') or
    -- fibroid ablation
    regexp_like(lower(procedure_name), 'fibroid|leiomyoma') or
    -- endometrial biopsy
    (regexp_like(lower(procedure_name), 'endometri') and 
    regexp_like(lower(procedure_name), 'bx|biopsy')))

