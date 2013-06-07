create or replace 
trigger cp_product_tbi 
 before insert on cp_product
 for each row
begin
 if :new.id_product IS NULL THEN 
    SELECT cp_product_seq.NEXTVAL INTO :new.id_product FROM sys.DUAL; 
 END IF;
end;