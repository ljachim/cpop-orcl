create or replace trigger cp_datastore_tbi 
 before insert on cp_datastore
 for each row
begin
 if :new.id_datastore IS NULL THEN 
    SELECT cp_datastore_seq.NEXTVAL INTO :new.id_datastore FROM sys.DUAL; 
 END IF;
end;