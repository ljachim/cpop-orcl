create or replace 
trigger cp_shop_tbi 
 before insert on cp_shop
 for each row
begin
 if :new.id_shop IS NULL THEN 
    SELECT cp_shop_seq.NEXTVAL INTO :new.id_shop FROM sys.DUAL; 
 END IF;
end;