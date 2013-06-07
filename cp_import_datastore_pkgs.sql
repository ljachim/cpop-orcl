create or replace 
PACKAGE cp_import_datastore_pkg IS

 FUNCTION new_location(a_abbreviation VARCHAR2, a_country VARCHAR2, a_region VARCHAR2, a_city VARCHAR2) RETURN NUMBER ;
 FUNCTION new_session (a_id NUMBER, a_id_location NUMBER, a_id_user NUMBER, a_id_batch NUMBER) RETURN NUMBER ;
 FUNCTION new_user    (a_name VARCHAR2, a_ip VARCHAR2) RETURN NUMBER;
 PROCEDURE import_datastore (a_min_id NUMBER, a_max_id NUMBER, a_batch_id NUMBER);
 PROCEDURE import_datastore_products (a_min_id NUMBER, a_max_id NUMBER, a_id_shop NUMBER, a_id_batch NUMBER);
 PROCEDURE import_hits_to_sales (a_min_id NUMBER, a_max_id NUMBER, a_id_session NUMBER, a_id_shop NUMBER);
 
END;