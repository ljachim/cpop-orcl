create or replace 
trigger cp_sale_tbi 
 before insert on cp_sale
 for each row
begin
 if :new.id_sale IS NULL THEN 
    SELECT cp_sale_seq.NEXTVAL INTO :new.id_sale FROM sys.DUAL; 
 END IF;
end;