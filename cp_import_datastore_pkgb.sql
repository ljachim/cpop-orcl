create or replace 
PACKAGE BODY cp_import_datastore_pkg IS


 FUNCTION list_element
      (p_string    VARCHAR2,
    	 p_element   INTEGER,
    	 p_separator VARCHAR2)
      RETURN	    VARCHAR2
    AS
      v_string     VARCHAR2(32767);
    BEGIN
      v_string := p_string || p_separator;
     FOR i IN 1 .. p_element - 1 LOOP
   	 v_string := SUBSTR(v_string,INSTR(v_string,p_separator)+1);
     END LOOP;
     RETURN SUBSTR(v_string,1,INSTR(v_string,p_separator)-1);
   END list_element;



 FUNCTION new_location(a_abbreviation VARCHAR2, a_country VARCHAR2, a_region VARCHAR2, a_city VARCHAR2) RETURN NUMBER 
   IS 
    v_id_location NUMBER;
   BEGIN
    BEGIN
       SELECT id_location 
         INTO v_id_location
         FROM cp_location 
           WHERE abbreviation LIKE a_abbreviation
             AND NVL(region,'region') LIKE NVL(a_region,'region')
             AND NVL(city,'city') LIKE NVL(a_city,'city');
       EXCEPTION  
         WHEN NO_DATA_FOUND THEN

         SELECT cp_location_seq.NEXTVAL 
           INTO v_id_location 
            FROM SYS.DUAL;
         
         INSERT INTO 
           cp_location(id_location,    abbreviation,     country,     region,   city)
           VALUES
                      (v_id_location,  LTRIM(RTRIM(a_abbreviation)),     LTRIM(RTRIM(a_country)),     LTRIM(RTRIM(a_region)),   LTRIM(RTRIM(a_city))); 
     END;
     RETURN v_id_location;
  END;
   
 FUNCTION new_session(a_id NUMBER, a_id_location NUMBER, a_id_user NUMBER, a_id_batch NUMBER) RETURN NUMBER
   IS 
     v_id_session NUMBER;
   BEGIN
    BEGIN
       SELECT id_session 
         INTO v_id_session
         FROM cp_session 
           WHERE id = a_id
             AND id_batch = a_id_batch
             AND id_user = a_id_user;
       EXCEPTION  
         WHEN NO_DATA_FOUND THEN

         SELECT cp_session_seq.NEXTVAL 
           INTO v_id_session 
            FROM SYS.DUAL;
         
         INSERT INTO 
           cp_session (id_session,    id_location,     id_user,     id,     id_batch)
           VALUES
                      (v_id_session,  a_id_location,   a_id_user,   a_id,   a_id_batch); 
     END;
     RETURN v_id_session;

   END;
   
 FUNCTION new_user (a_name VARCHAR2, a_ip VARCHAR2 ) RETURN NUMBER 
   IS 
     v_id_user NUMBER;
   BEGIN
    BEGIN
       SELECT id_user 
         INTO v_id_user
         FROM cp_user 
           WHERE name LIKE a_name ;
           
       EXCEPTION  
         WHEN NO_DATA_FOUND THEN

         SELECT cp_user_seq.NEXTVAL 
           INTO v_id_user 
            FROM SYS.DUAL;
         
         INSERT INTO 
           cp_user (id_user,    name,     ipaddress)
           VALUES
                   (v_id_user, LTRIM(RTRIM(a_name)), NULL); 
     END;
     RETURN v_id_user;
   END;
   
 PROCEDURE import_datastore (a_min_id NUMBER, a_max_id NUMBER, a_batch_id NUMBER)
   IS 
     --
     v_id_user NUMBER; 
     v_id_location NUMBER;
     v_id_session NUMBER;
     v_abbreviation VARCHAR2(3);
     v_country VARCHAR2(50);
     v_region VARCHAR2(50); 
     v_city VARCHAR2(50);
     --
     CURSOR c_datastore IS SELECT 
      id_datastore,   userinfo,   location,
      id,             step,       path,
      category,       uri_parameter,     timestamp,
      url
      FROM cp_datastore
      WHERE processed = 'N'
       and id_datastore between a_min_id and a_max_id;
      --
      v_datastore_rec c_datastore%ROWTYPE ;
      --
   BEGIN
      FOR v_datastore_rec IN c_datastore
      LOOP
         v_id_user := new_user (v_datastore_rec.userinfo, NULL);
         
         
         -- parse location
         
         
         v_abbreviation := REPLACE( list_element (v_datastore_rec.location, 1, '"'), '"', NULL );
         v_country      := REPLACE( list_element (v_datastore_rec.location, 2, '"'), '"', NULL );
         v_region       := REPLACE( list_element (v_datastore_rec.location, 3, '"'), '"', NULL );
         v_city         := REPLACE( list_element (v_datastore_rec.location, 4, '"'), '"', NULL );
         
         --
         v_id_location := new_location (v_abbreviation,v_country, v_region, v_city);
         
         v_id_session := new_session (v_datastore_rec.id, v_id_location, v_id_user, a_batch_id);
         -- zvazit moznost ukladat si (alespon prozatim) idcko datastoru pro hledani erroru a nejasnosti
         -- userid? y/n?
         INSERT INTO cp_hit 
          (step,                      category,                       uri_parameter, 
           timestamp,                 
           url,                            id_session, 
           path)
           VALUES
          (TO_NUMBER(v_datastore_rec.step),      v_datastore_rec.category,       v_datastore_rec.uri_parameter, 
           to_date('1970-01-01','YYYY-MM-DD') + numtodsinterval(TO_NUMBER(v_datastore_rec.timestamp),'SECOND'),
           v_datastore_rec.url,            v_id_session, 
           v_datastore_rec.path) ;
         --
         UPDATE cp_datastore SET processed = 'Y' WHERE id_datastore = v_datastore_rec.id_datastore ;
      END LOOP;
      
   END;

PROCEDURE import_datastore_products (a_min_id NUMBER, a_max_id NUMBER, a_id_shop NUMBER, a_id_batch NUMBER)
IS
  CURSOR c_datastore_step2 IS
    SELECT id_datastore_step2, product_id 
      FROM cp_datastore_step2
        WHERE processed = 'N'
          AND id_datastore_step2 BETWEEN a_min_id AND a_max_id ;
  v_datastore_step2_rec c_datastore_step2%ROWTYPE ;        
BEGIN
  FOR v_datastore_step2_rec IN c_datastore_step2 
  LOOP
    INSERT INTO cp_product 
     (productid,    id_shop,    id_batch)
     VALUES
     (v_datastore_step2_rec.product_id,  a_id_shop, a_id_batch) ;
    UPDATE cp_datastore_step2 SET processed = 'Y' where id_datastore_step2 = v_datastore_step2_rec.id_datastore_step2 ; 
  END LOOP;

END;
--
FUNCTION parse_productid (a_uri_parameter CLOB) RETURN VARCHAR2
IS
  v_retval VARCHAR2(255);
BEGIN
  v_retval := RTRIM(SUBSTR(a_uri_parameter, INSTR(a_uri_parameter, 'pid=')+4)) ;
  IF v_retval IS NULL THEN v_retval := '0'; END IF;
  RETURN v_retval;
END;
--
FUNCTION new_product (a_productid VARCHAR2, a_id_shop NUMBER) RETURN NUMBER
IS
  v_id_product NUMBER;
BEGIN
 
   BEGIN
     SELECT id_product 
         INTO v_id_product
         FROM cp_product 
           WHERE productid LIKE a_productid
             AND id_shop = a_id_shop;
           
       EXCEPTION  
         WHEN NO_DATA_FOUND THEN
            SELECT cp_product_seq.NEXTVAL 
                INTO v_id_product 
                    FROM SYS.DUAL;
            INSERT INTO cp_product
              (id_product, productid, id_shop)
            VALUES
              (v_id_product, a_productid, a_id_shop);
   END;           
 
   RETURN v_id_product; 
 
END;
--
PROCEDURE import_hits_to_sales (a_min_id NUMBER, a_max_id NUMBER, a_id_session NUMBER, a_id_shop NUMBER)
IS
CURSOR c_hit IS
  SELECT id_hit, category, uri_parameter, timestamp
    FROM cp_hit
      WHERE id_hit BETWEEN a_min_id AND a_max_id
         AND id_session = a_id_session
         AND category in (1, 2, 3)
         AND processed = 'N'
          ORDER BY step;
v_hit_rec c_hit%ROWTYPE ; 
v_productid   NUMBER;
v_id_product  NUMBER;
v_id_user     NUMBER;
v_id_sale     NUMBER; 
BEGIN
  -- Potencialni prostor pro optimalizaci!!
  SELECT id_user INTO v_id_user
    FROM cp_session 
      WHERE id_session = a_id_session;
  --
  FOR v_hit_rec IN c_hit LOOP
    IF (v_hit_rec.category = 1) THEN
      -- browse
      -- parse id_product from uri_parameter
      v_productid  := parse_productid (v_hit_rec.uri_parameter);
      v_id_product := new_product (v_productid, a_id_shop);
      -- insert 
      INSERT INTO cp_sale_product
        (id_product,   id_user,   timestamp)
         VALUES
        (v_id_product,  v_id_user, v_hit_rec.timestamp);
      --  
    ELSIF (v_hit_rec.category = 2) THEN
    -- basket
    -- pocitam s tim, ze productid je vyplneny z predchoziho kroku
    -- TODO ale presto bych ten string mel parsovat, abych zjistil mnozstvi!!!
    -- create cp_sale with empty sale_date
      IF v_id_sale IS NULL THEN
         SELECT cp_sale_seq.NEXTVAL INTO v_id_sale FROM SYS.DUAL;
         INSERT INTO cp_sale (id_sale, id_shop) VALUES (v_id_sale, a_id_shop);
      END IF;
      --
      INSERT INTO cp_sale_product
        (id_product, id_user, timestamp, id_sale)
        VALUES
        (v_id_product,  v_id_user, v_hit_rec.timestamp, v_id_sale);
      --  
    ELSIF (v_hit_rec.category = 3) THEN
    -- order
    UPDATE cp_sale 
      SET sale_date = v_hit_rec.timestamp
       WHERE id_sale = v_id_sale;
    --   
    END IF;
    --
    UPDATE cp_hit SET processed = 'Y' WHERE id_hit = v_hit_rec.id_hit;
    --
  END LOOP;
  -- TODO_neresim situaci, kdy uzivatel vec VYNDA z KOSIKU !!!!
END;

BEGIN
  NULL;
END;