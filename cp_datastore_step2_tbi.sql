create or replace trigger cp_datastore_step2_tbi 
 before insert on cp_datastore_step2
 for each row
begin
 if :new.id_datastore_step2 IS NULL THEN 
    SELECT cp_datastore_seq.NEXTVAL INTO :new.id_datastore_step2 FROM sys.DUAL; 
 END IF;
end;