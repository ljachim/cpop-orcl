create or replace 
PACKAGE BODY cp_webservices_in_pkg IS

PROCEDURE import_xml_test_01
IS

  req          utl_http.req;
  resp         utl_http.resp;
  value        VARCHAR2(1024);
  temp_clob     clob;
  v_first      boolean := TRUE;

BEGIN
    dbms_lob.createtemporary(temp_clob, TRUE, dbms_lob.call);
    dbms_lob.open(temp_clob, dbms_lob.lob_readwrite);

--  utl_http.set_proxy('proxy.my-company.com', 'corp.my-company.com');

  req := utl_http.begin_request('http://devsrv.goldthorp.com:7777/pls/casexml.xml_export');
  utl_http.set_header(req, 'User-Agent', 'Mozilla/4.0');
  resp := utl_http.get_response(req);
  LOOP
    utl_http.read_line(resp, value, TRUE);

    if v_first then
       v_first := FALSE;
       dbms_lob.write(temp_clob, length(value), 1, value);
    else
       dbms_lob.writeappend(temp_clob,length(value),value);
    end if;

  END LOOP;
  utl_http.end_response(resp);
  dbms_lob.close(temp_clob);
  dbms_lob.freetemporary(temp_clob);

 EXCEPTION
   WHEN utl_http.end_of_body THEN
    utl_http.end_response(resp);
  dbms_output.put_line('end loop');
  dbms_output.put_line(dbms_lob.getlength(temp_clob));
  -- insert into xml_load_data values (xml_element_seq.nextval, sys.XMLType.createXML(temp_clob));

  dbms_lob.close(temp_clob);
  dbms_lob.freetemporary(temp_clob);
END;

FUNCTION new_selection_list(a_list CLOB) RETURN VARCHAR2
IS
   json_obj json;
   json_lst json_list;
   v_ret_str VARCHAR2(255);
   v_idselection NUMBER;
BEGIN
   json_obj := json (a_list);
   json_lst := json_list (json_obj.get('productId'));

   SELECT cp_selection_product_seq.NEXTVAL INTO v_idselection FROM sys.DUAL; 
   v_ret_str := TO_CHAR (v_idselection); -- || ' : ' ;

   for i in 1..json_lst.count loop
     -- v_ret_str := v_ret_str || '+' || json_value.get_string(json_lst.get(i)) ;
     insert into selection_product (id_selection, productid)
     values (v_idselection, json_value.get_string(json_lst.get(i)));
     
   end loop;
   
   RETURN v_ret_str;

END;

FUNCTION orders (a_shopid VARCHAR2, a_datefrom VARCHAR2, a_dateto VARCHAR2, a_selectionid VARCHAR2) RETURN VARCHAR2
IS
  v_retval NUMBER;
  v_datefrom DATE;
  v_dateto DATE;
  v_selectionid NUMBER;
BEGIN
v_datefrom := TO_DATE(a_datefrom, 'MM-DD-YYYY');
v_dateto   := TO_DATE(a_dateto,   'MM-DD-YYYY');
--
IF LENGTH(TRIM(TRANSLATE(a_selectionid, '0123456789', ' '))) IS NULL THEN
   v_selectionid := to_number(a_selectionid);
END IF;
--
IF v_selectionid IS NULL THEN
  select count(distinct s.id_sale) into v_retval
    from cp_sale s, cp_sale_product sp
      where s.id_shop = TO_NUMBER(a_shopid)
        and s.sale_date between v_datefrom and v_dateto
      and s.id_sale = sp.id_sale
      and sp.id_sale IS NOT NULL;
ELSE
  select count(distinct s.id_sale) into v_retval
    from cp_sale s, cp_sale_product sp
      where s.id_shop = TO_NUMBER(a_shopid)
        and s.sale_date between v_datefrom and v_dateto
      and s.id_sale = sp.id_sale
      and sp.id_sale IS NOT NULL
      and sp.id_product in (select p.id_product from cp_product p, selection_product sel where p.productid = sel.productid and sel.id_selection = v_selectionid);
END IF;

RETURN to_char(nvl(v_retval, 0));

END;


FUNCTION sales  (a_shopid VARCHAR2, a_datefrom VARCHAR2, a_dateto VARCHAR2, a_selectionid VARCHAR2) RETURN VARCHAR2
IS
  v_retval NUMBER;
  v_datefrom DATE;
  v_dateto DATE;
  v_selectionid NUMBER;
BEGIN
v_datefrom := TO_DATE(a_datefrom, 'MM-DD-YYYY');
v_dateto   := TO_DATE(a_dateto,   'MM-DD-YYYY');
--
IF LENGTH(TRIM(TRANSLATE(a_selectionid, '0123456789', ' '))) IS NULL THEN
   v_selectionid := to_number(a_selectionid);
END IF;
--
IF v_selectionid IS NULL THEN
    select sum(p.price) into v_retval
      from cp_sale s, cp_sale_product sp, cp_product p
        where s.id_shop = TO_NUMBER(a_shopid)
          and s.sale_date between v_datefrom and v_dateto
        and s.id_sale = sp.id_sale
        and sp.id_product = p.id_product 
        and sp.id_sale IS NOT NULL;
ELSE
    select sum(p.price) into v_retval
      from cp_sale s, cp_sale_product sp, cp_product p, selection_product sel 
        where s.id_shop = TO_NUMBER(a_shopid)
          and s.sale_date between v_datefrom and v_dateto
        and s.id_sale = sp.id_sale
        and p.productid = sel.productid
        and sp.id_product = p.id_product 
        and sp.id_sale IS NOT NULL
        and sel.id_selection = v_selectionid;
END IF;        
--
RETURN to_char(nvl(v_retval, 0));
--
END;
--
FUNCTION grafsales_tab (a_shopid VARCHAR2, a_datefrom VARCHAR2, a_dateto VARCHAR2, a_selectionid VARCHAR2) RETURN t_nt_grafsales 

IS
  v_datefrom DATE;
  v_dateto DATE;
  v_selectionid NUMBER;

--
cursor c_grafsales is
    select sum(p.price) as sales, TRUNC(s.sale_date) as sale_date
      from cp_sale s, cp_sale_product sp, cp_product p
        where s.id_shop = TO_NUMBER(a_shopid)
        and s.sale_date between v_datefrom and v_dateto
        and s.id_sale = sp.id_sale
        and sp.id_product = p.id_product 
        and sp.id_sale IS NOT NULL
        group by TRUNC(s.sale_date)
        order by sale_date;
--
cursor c_grafsales_sel is
    select sum(p.price) as sales, TRUNC(s.sale_date) as sale_date
      from cp_sale s, cp_sale_product sp, cp_product p, selection_product sel 
        where s.id_shop = TO_NUMBER(a_shopid)
        and s.sale_date between v_datefrom and v_dateto
        and s.id_sale = sp.id_sale
        and p.productid = sel.productid
        and sp.id_product = p.id_product 
        and sp.id_sale IS NOT NULL
        and sel.id_selection = nvl(v_selectionid, sel.id_selection)
        group by TRUNC(s.sale_date)
        order by sale_date;
--        
  v_grafsales_rec c_grafsales%ROWTYPE;    
  v_grafsales_sel_rec c_grafsales_sel%ROWTYPE;    
--
   v_ret t_nt_grafsales;

BEGIN
    v_ret := t_nt_grafsales();
    
    v_datefrom := TO_DATE(a_datefrom, 'MM-DD-YYYY');
    v_dateto   := TO_DATE(a_dateto,   'MM-DD-YYYY');
    --
    IF LENGTH(TRIM(TRANSLATE(a_selectionid, '0123456789', ' '))) IS NULL THEN
       v_selectionid := to_number(a_selectionid);
    END IF;
    IF v_selectionid IS NULL THEN
        FOR v_grafsales_rec IN c_grafsales
        LOOP
           v_ret.extend;
           v_ret(v_ret.count) := t_graf(v_grafsales_rec.sales, TO_CHAR(v_grafsales_rec.sale_date));
        END LOOP;
    ELSE
        FOR v_grafsales_rec_sel IN c_grafsales_sel
        LOOP
           v_ret.extend;
           v_ret(v_ret.count) := t_graf(v_grafsales_rec.sales, TO_CHAR(v_grafsales_rec.sale_date));
        END LOOP;
    END IF;
 return v_ret;
END;

--
FUNCTION graforders (a_shopid VARCHAR2, a_datefrom VARCHAR2, a_dateto VARCHAR2, a_selectionid VARCHAR2) RETURN CLOB
IS
  v_datefrom DATE;
  v_dateto DATE;
  v_selectionid NUMBER;
--
cursor c_graforders_sel is
  select count(distinct s.id_sale) as orders, TRUNC(s.sale_date) as sale_date 
    from cp_sale s, cp_sale_product sp
      where s.id_shop = TO_NUMBER(a_shopid)
        and s.sale_date between v_datefrom and v_dateto
      and s.id_sale = sp.id_sale
      and sp.id_sale IS NOT NULL
      and sp.id_product in (select p.id_product from cp_product p, selection_product sel where p.productid = sel.productid and sel.id_selection = nvl(v_selectionid, sel.id_selection))
      group by TRUNC(s.sale_date)
       order by sale_date;
--
cursor c_graforders is
  select count(distinct s.id_sale) as orders, TRUNC(s.sale_date) as sale_date 
    from cp_sale s, cp_sale_product sp
      where s.id_shop = TO_NUMBER(a_shopid)
        and s.sale_date between v_datefrom and v_dateto
      and s.id_sale = sp.id_sale
      and sp.id_sale IS NOT NULL
      group by TRUNC(s.sale_date)
       order by sale_date;
--
  v_graforders_sel_rec c_graforders_sel%ROWTYPE; 
  v_graforders_rec c_graforders%ROWTYPE;    
  jsonArray        json_list;
  jsonObj          json;


BEGIN
    v_datefrom := TO_DATE(a_datefrom, 'MM-DD-YYYY');
    v_dateto   := TO_DATE(a_dateto,   'MM-DD-YYYY');
    --
    IF LENGTH(TRIM(TRANSLATE(a_selectionid, '0123456789', ' '))) IS NULL THEN
       v_selectionid := to_number(a_selectionid);
    END IF;
    jsonArray := json_list();

    IF v_selectionid IS NULL THEN
        FOR v_graforders_rec IN c_graforders
        LOOP
           jsonObj := json();
           jsonObj.put ('orders', v_graforders_rec.orders);
           jsonObj.put ('date',  TO_CHAR(v_graforders_rec.sale_date));
           jsonArray.append(jsonObj.to_json_value);
        END LOOP;
    ELSE
        FOR v_graforders_sel_rec IN c_graforders_sel
        LOOP
           jsonObj := json();
           jsonObj.put ('orders', v_graforders_sel_rec.orders);
           jsonObj.put ('date',  TO_CHAR(v_graforders_sel_rec.sale_date));
           jsonArray.append(jsonObj.to_json_value);
        END LOOP;
    
    END IF;

    RETURN jsonArray.to_char;


END;
--  
FUNCTION grafsales  (a_shopid VARCHAR2, a_datefrom VARCHAR2, a_dateto VARCHAR2, a_selectionid VARCHAR2) RETURN CLOB
IS
  v_datefrom DATE;
  v_dateto DATE;
  v_selectionid NUMBER;
  v_retstr CLOB;
--
cursor c_grafsales is
    select sum(p.price) as sales, TRUNC(s.sale_date) as sale_date
      from cp_sale s, cp_sale_product sp, cp_product p
        where s.id_shop = TO_NUMBER(a_shopid)
        and s.sale_date between v_datefrom and v_dateto
        and s.id_sale = sp.id_sale
        and sp.id_product = p.id_product 
        and sp.id_sale IS NOT NULL
        group by TRUNC(s.sale_date)
        order by sale_date;
--
cursor c_grafsales_sel is
    select sum(p.price) as sales, TRUNC(s.sale_date) as sale_date
      from cp_sale s, cp_sale_product sp, cp_product p, selection_product sel 
        where s.id_shop = TO_NUMBER(a_shopid)
        and s.sale_date between v_datefrom and v_dateto
        and s.id_sale = sp.id_sale
        and p.productid = sel.productid
        and sp.id_product = p.id_product 
        and sp.id_sale IS NOT NULL
        and sel.id_selection = nvl(v_selectionid, sel.id_selection)
        group by TRUNC(s.sale_date)
        order by sale_date;
--        
  v_grafsales_rec c_grafsales%ROWTYPE;    
  v_grafsales_sel_rec c_grafsales_sel%ROWTYPE;    
  jsonArray        json_list;
  jsonObj          json;
BEGIN

    v_datefrom := TO_DATE(a_datefrom, 'MM-DD-YYYY');
    v_dateto   := TO_DATE(a_dateto,   'MM-DD-YYYY');
    --
    IF LENGTH(TRIM(TRANSLATE(a_selectionid, '0123456789', ' '))) IS NULL THEN
       v_selectionid := to_number(a_selectionid);
    END IF;
    jsonArray := json_list();

    IF v_selectionid IS NULL THEN
        FOR v_grafsales_rec IN c_grafsales
        LOOP
           jsonObj := json();
           jsonObj.put ('sales', v_grafsales_rec.sales);
           jsonObj.put ('date',  TO_CHAR(v_grafsales_rec.sale_date));
           jsonArray.append(jsonObj.to_json_value);
        END LOOP;
    ELSE
        FOR v_grafsales_rec_sel IN c_grafsales_sel
        LOOP
           jsonObj := json();
           jsonObj.put ('sales', v_grafsales_rec_sel.sales);
           jsonObj.put ('date',  TO_CHAR(v_grafsales_rec_sel.sale_date));
           jsonArray.append(jsonObj.to_json_value);
        END LOOP;
    END IF;
    RETURN jsonArray.to_char;

END;
--
FUNCTION topfive_tab (a_shopid VARCHAR2, a_datefrom VARCHAR2, a_dateto VARCHAR2, a_selectionid VARCHAR2) RETURN t_nt_topfive
IS
  v_datefrom DATE;
  v_dateto DATE;
  v_selectionid NUMBER;
  v_ret    t_nt_topfive;
 --
 cursor c_topfive is
 select product, orders, visits, id_product, revenue from (
    select ords.*, p2.price*ords.orders as revenue, ROW_NUMBER() OVER (ORDER BY orders desc) r from (
      select p.description as product, 
             count(distinct s.id_sale) as orders,
             count(cp.id_sale) as visits,
             p.id_product
      from cp_product p, 
           cp_sale_product cp,
           cp_sale s 
        where cp.id_product = p.id_product
          and cp.id_sale IS NOT NULL
          and s.id_shop = TO_NUMBER(a_shopid)
          and p.price is not null
          and s.id_sale = cp.id_sale
          and s.sale_date between v_datefrom and v_dateto
            group by p.description, p.id_product 
            ) ords, 
            cp_product p2
              where p2.id_product = ords.id_product
               order by revenue desc)
                where r < 6
           ; 
 --
 cursor c_topfive_sel is
 select product, orders, visits, id_product, revenue from (
    select ords.*, p2.price*ords.orders as revenue, ROW_NUMBER() OVER (ORDER BY orders) r from (
      select p.description as product, 
             count(distinct s.id_sale) as orders,
             count(cp.id_sale) as visits,
             p.id_product
      from cp_product p, 
           cp_sale_product cp,
           cp_sale s, 
           selection_product sp
        where cp.id_product = p.id_product
          and sp.productid(+)  = p.productid
          and cp.id_sale IS NOT NULL
          and s.id_shop = TO_NUMBER(a_shopid)
          and s.id_sale = cp.id_sale
          and s.sale_date between v_datefrom and v_dateto
          and sp.id_selection = nvl(v_selectionid, sp.id_selection)
            group by p.description, p.id_product 
            ) ords, 
            cp_product p2
              where p2.id_product = ords.id_product
               order by revenue)
                where r < 5
           ; 
 --
  v_topfive_rec c_topfive%ROWTYPE;   
  v_topfive_sel_rec c_topfive_sel%ROWTYPE;   
BEGIN

    v_datefrom := TO_DATE(a_datefrom, 'MM-DD-YYYY');
    v_dateto   := TO_DATE(a_dateto,   'MM-DD-YYYY');
    --
    IF LENGTH(TRIM(TRANSLATE(a_selectionid, '0123456789', ' '))) IS NULL THEN
       v_selectionid := to_number(a_selectionid);
    END IF;
    v_ret      := t_nt_topfive();
    IF v_selectionid IS NULL THEN
        FOR v_topfive_rec IN c_topfive
        LOOP
           v_ret.extend;
           v_ret(v_ret.count) := t_topfive
              (product => NVL(v_topfive_rec.product,'noname'),
               orders  => v_topfive_rec.orders,
               visits  => v_topfive_rec.visits,
               idproduct=> v_topfive_rec.id_product,
               productid=> NULL,
               revenuer => v_topfive_rec.revenue
              );
        END LOOP;
    ELSE
        FOR v_topfive_sel_rec IN c_topfive_sel
        LOOP
           v_ret.extend;
           v_ret(v_ret.count) := t_topfive
              (product => NVL(v_topfive_rec.product,'noname'),
               orders  => v_topfive_rec.orders,
               visits  => v_topfive_rec.visits,
               idproduct=> v_topfive_rec.id_product,
               productid=> NULL,
               revenuer => v_topfive_rec.revenue
              );
        END LOOP;
    END IF;

    RETURN v_ret;

END;


--
FUNCTION topfive (a_shopid VARCHAR2, a_datefrom VARCHAR2, a_dateto VARCHAR2, a_selectionid VARCHAR2) RETURN CLOB
IS
  v_datefrom DATE;
  v_dateto DATE;
  v_selectionid NUMBER;
  v_retstr CLOB;
 --
 cursor c_topfive is
 select product, orders, visits, id_product, revenue from (
    select ords.*, p2.price*ords.orders as revenue, ROW_NUMBER() OVER (ORDER BY orders) r from (
      select p.description as product, 
             count(distinct s.id_sale) as orders,
             count(cp.id_sale) as visits,
             p.id_product
      from cp_product p, 
           cp_sale_product cp,
           cp_sale s 
        where cp.id_product = p.id_product
          and cp.id_sale IS NOT NULL
          and s.id_shop = TO_NUMBER(a_shopid)
          and s.id_sale = cp.id_sale
          and s.sale_date between v_datefrom and v_dateto
            group by p.description, p.id_product 
            ) ords, 
            cp_product p2
              where p2.id_product = ords.id_product
               order by revenue)
                where r < 5
           ; 
 --
 cursor c_topfive_sel is
 select product, orders, visits, id_product, revenue from (
    select ords.*, p2.price*ords.orders as revenue, ROW_NUMBER() OVER (ORDER BY orders) r from (
      select p.description as product, 
             count(distinct s.id_sale) as orders,
             count(cp.id_sale) as visits,
             p.id_product
      from cp_product p, 
           cp_sale_product cp,
           cp_sale s, 
           selection_product sp
        where cp.id_product = p.id_product
          and sp.productid(+)  = p.productid
          and cp.id_sale IS NOT NULL
          and s.id_shop = TO_NUMBER(a_shopid)
          and s.id_sale = cp.id_sale
          and s.sale_date between v_datefrom and v_dateto
          and sp.id_selection = nvl(v_selectionid, sp.id_selection)
            group by p.description, p.id_product 
            ) ords, 
            cp_product p2
              where p2.id_product = ords.id_product
               order by revenue)
                where r < 5
           ; 
 --
  v_topfive_rec c_topfive%ROWTYPE;   
  v_topfive_sel_rec c_topfive_sel%ROWTYPE;   
  jsonArray        json_list;
  jsonObj          json;
BEGIN

    v_datefrom := TO_DATE(a_datefrom, 'MM-DD-YYYY');
    v_dateto   := TO_DATE(a_dateto,   'MM-DD-YYYY');
    --
    IF LENGTH(TRIM(TRANSLATE(a_selectionid, '0123456789', ' '))) IS NULL THEN
       v_selectionid := to_number(a_selectionid);
    END IF;
    jsonArray := json_list();
    IF v_selectionid IS NULL THEN
        FOR v_topfive_rec IN c_topfive
        LOOP
           jsonObj := json();
           jsonObj.put ('product', v_topfive_rec.product);
           jsonObj.put ('orders',  v_topfive_rec.orders);
           jsonObj.put ('visits',  v_topfive_rec.visits);
           jsonObj.put ('id_product', v_topfive_rec.id_product);
           jsonObj.put ('revenue', v_topfive_rec.revenue);
           jsonArray.append(jsonObj.to_json_value);
        END LOOP;
    ELSE
        FOR v_topfive_sel_rec IN c_topfive_sel
        LOOP
           jsonObj := json();
           jsonObj.put ('product', v_topfive_sel_rec.product);
           jsonObj.put ('orders',  v_topfive_sel_rec.orders);
           jsonObj.put ('visits',  v_topfive_sel_rec.visits);
           jsonObj.put ('id_product', v_topfive_sel_rec.id_product);
           jsonObj.put ('revenue', v_topfive_sel_rec.revenue);
           jsonArray.append(jsonObj.to_json_value);
        END LOOP;
    END IF;

    RETURN jsonArray.to_char;

END;
--
FUNCTION lowfive (a_shopid VARCHAR2, a_datefrom VARCHAR2, a_dateto VARCHAR2, a_selectionid VARCHAR2) RETURN CLOB
IS
  v_datefrom DATE;
  v_dateto DATE;
  v_selectionid NUMBER;
  v_retstr CLOB;
 --
 cursor c_topfive is
 select product, orders, visits, id_product, revenue from (
    select ords.*, p2.price*ords.orders as revenue, ROW_NUMBER() OVER (ORDER BY orders) r from (
      select p.description as product, 
             count(distinct s.id_sale) as orders,
             count(cp.id_sale) as visits,
             p.id_product
      from cp_product p, 
           cp_sale_product cp,
           cp_sale s
        where cp.id_product = p.id_product
          and cp.id_sale IS NOT NULL
          and s.id_shop = TO_NUMBER(a_shopid)
          and s.id_sale = cp.id_sale
          and s.sale_date between v_datefrom and v_dateto
            group by p.description, p.id_product 
            ) ords, 
            cp_product p2
              where p2.id_product = ords.id_product
              order by revenue desc)
                where r < 5
           ; 
 --
 cursor c_topfive_sel is
 select product, orders, visits, id_product, revenue from (
    select ords.*, p2.price*ords.orders as revenue, ROW_NUMBER() OVER (ORDER BY orders) r from (
      select p.description as product, 
             count(distinct s.id_sale) as orders,
             count(cp.id_sale) as visits,
             p.id_product
      from cp_product p, 
           cp_sale_product cp,
           cp_sale s,
           selection_product sp
        where cp.id_product = p.id_product
          and sp.productid(+)  = p.productid
          and cp.id_sale IS NOT NULL
          and s.id_shop = TO_NUMBER(a_shopid)
          and s.id_sale = cp.id_sale
          and s.sale_date between v_datefrom and v_dateto
          and sp.id_selection = nvl(v_selectionid, sp.id_selection)
            group by p.description, p.id_product 
            ) ords, 
            cp_product p2
              where p2.id_product = ords.id_product
              order by revenue desc)
                where r < 5
           ; 
  v_topfive_rec        c_topfive%ROWTYPE;   
  v_topfive_sel_rec    c_topfive_sel%ROWTYPE;   
  jsonArray        json_list;
  jsonObj          json;
BEGIN

    v_datefrom := TO_DATE(a_datefrom, 'MM-DD-YYYY');
    v_dateto   := TO_DATE(a_dateto,   'MM-DD-YYYY');
    --
    IF LENGTH(TRIM(TRANSLATE(a_selectionid, '0123456789', ' '))) IS NULL THEN
       v_selectionid := to_number(a_selectionid);
    END IF;
    jsonArray := json_list();
    IF v_selectionid IS NULL THEN
        FOR v_topfive_rec IN c_topfive
        LOOP
           jsonObj := json();
           jsonObj.put ('product', v_topfive_rec.product);
           jsonObj.put ('orders',  v_topfive_rec.orders);
           jsonObj.put ('visits',  v_topfive_rec.visits);
           jsonObj.put ('id_product', v_topfive_rec.id_product);
           jsonObj.put ('revenue', v_topfive_rec.revenue);
           jsonArray.append(jsonObj.to_json_value);
        END LOOP;
    ELSE
        FOR v_topfive_sel_rec IN c_topfive_sel
        LOOP
           jsonObj := json();
           jsonObj.put ('product', v_topfive_sel_rec.product);
           jsonObj.put ('orders',  v_topfive_sel_rec.orders);
           jsonObj.put ('visits',  v_topfive_sel_rec.visits);
           jsonObj.put ('id_product', v_topfive_sel_rec.id_product);
           jsonObj.put ('revenue', v_topfive_sel_rec.revenue);
           jsonArray.append(jsonObj.to_json_value);
        END LOOP;
    END IF;

    RETURN jsonArray.to_char;

END;
--
FUNCTION visitors (a_shopid VARCHAR2, a_datefrom VARCHAR2, a_dateto VARCHAR2, a_selectionid VARCHAR2) RETURN VARCHAR2
IS
  v_retval NUMBER;
  v_datefrom DATE;
  v_dateto DATE;
  v_selectionid NUMBER;
BEGIN
  v_datefrom := TO_DATE(a_datefrom, 'MM-DD-YYYY');
  v_dateto   := TO_DATE(a_dateto,   'MM-DD-YYYY');
  --
  IF LENGTH(TRIM(TRANSLATE(a_selectionid, '0123456789', ' '))) IS NULL THEN
     v_selectionid := to_number(a_selectionid);
  END IF;
  --
  IF v_selectionid IS NULL THEN
      select count(distinct s.id_user) into v_retval
       from cp_session s, cp_hit h, cp_batch b
         where h.id_session = s.id_session
           and s.id_batch = b.id_batch
           and b.id_shop = TO_NUMBER(a_shopid)
           and h.timestamp between v_datefrom and v_dateto;
  ELSE
     select count(distinct cp.id_user) into v_retval
     from cp_sale_product cp, selection_product sp, cp_product p
       where sp.id_selection = v_selectionid
         and p.id_shop = TO_NUMBER(a_shopid)
         and cp.id_product = p.id_product
         and p.productid = sp.productid
         and cp.timestamp between v_datefrom and v_dateto;
  END IF;
  --     
  RETURN to_char(nvl(v_retval, 0));
  --
END;
--
FUNCTION import_product_data(a_list CLOB) RETURN VARCHAR2
-- importuje GAP.json (soubor s daty o produktech)
-- a updatuje pro ne detail produktu
-- Pozn.: mozna by bylo lepsi to sjednotit s importem produktu
IS
   json_obj json;
   json_lst json_list;
   v_ret_str VARCHAR2(255);
BEGIN
   -- TODO !!!! Nefunguje to !!!!
   json_lst := json_list (a_list);
   
   json_obj := json(a_list);
   json_lst := json_list (json_obj.get('index'));
   for i in 1..json_lst.count loop
       v_ret_str := v_ret_str || '+' || json_value.get_string(json_lst.get(i)) ;
   end loop;
--   
   -- v_ret_str := 'OK' ;
   RETURN v_ret_str;
END;
--
BEGIN
  NULL;
END;