-- query for surgical procedures related to UF and Endo

select *
from sr3452058_table4_surgical_procedure
where (procedure_code in ('1962', '38589', '58150', '58180', '58210', '58260','58541', '58542', '58544',
    '58550', '58553', '58570', '58572', '58573', 'SHX1221', 'SHX1223', 'SHX1926', 'SHX1934', 'SHX209',
    'SHX210', 'SHX21050', 'SHX2362', 'SHX2548', 'SHX81', 'SHX82', 'SUR292', 'SUR658', 'SUR661', 
    'SUR797', 'SUR800', '58925', 'SHX85') or
    regexp_like(lower(procedure_name), 'hysterectomy|oophorectomy|salpingectomy|myomectomy'))

