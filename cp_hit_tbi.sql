create or replace trigger cp_hit_tbi 
 before insert on cp_hit
 for each row
begin
 if :new.id_hit IS NULL THEN 
    SELECT cp_hit_seq.NEXTVAL INTO :new.id_hit FROM sys.DUAL; 
 END IF;
end;