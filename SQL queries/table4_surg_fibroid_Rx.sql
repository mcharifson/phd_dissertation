-- additional fibroid treatments

select *
from sr3452058_table4_surgical_procedure
where 
    -- ablation
    regexp_like(lower(procedure_name), 'ablation endometrial') or
    -- fibroid dilation or curettage
    regexp_like(lower(procedure_name), 'dilation and curettage')
