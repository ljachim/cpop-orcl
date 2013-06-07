create or replace 
procedure cp_import is

  v_batch NUMBER;
 
begin
 
  SELECT cp_batch_seq.NEXTVAL INTO v_batch from SYS.DUAL;
  INSERT INTO cp_batch (id_batch) VALUES (v_batch) ; 

/*
begin
  cp_import_datastore_pkg.import_datastore (6050, 6360, 2);
  -- zpracuje to logy z webu GAP do logicke struktury; krok 1
  commit;
end;

begin
  cp_import_datastore_pkg.import_datastore_products (5881, 6100, 41, 3);
  -- zpracuje to produkty z webu gap do tabulky products, krok 2
  commit;
end;

begin
  cp_import_datastore_pkg.import_hits_to_sales (0, 116360, 44, 41);
  commit;
end; 


*/
 
end;