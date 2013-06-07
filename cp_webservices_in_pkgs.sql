create or replace 
PACKAGE cp_webservices_in_pkg IS
  PROCEDURE import_xml_test_01;
  FUNCTION new_selection_list(a_list CLOB) RETURN VARCHAR2;
  FUNCTION orders (a_shopid VARCHAR2, a_datefrom VARCHAR2, a_dateto VARCHAR2, a_selectionid VARCHAR2) RETURN VARCHAR2;
  FUNCTION sales  (a_shopid VARCHAR2, a_datefrom VARCHAR2, a_dateto VARCHAR2, a_selectionid VARCHAR2) RETURN VARCHAR2;
  FUNCTION graforders (a_shopid VARCHAR2, a_datefrom VARCHAR2, a_dateto VARCHAR2, a_selectionid VARCHAR2) RETURN CLOB;
  FUNCTION grafsales  (a_shopid VARCHAR2, a_datefrom VARCHAR2, a_dateto VARCHAR2, a_selectionid VARCHAR2) RETURN CLOB;
  FUNCTION grafsales_tab (a_shopid VARCHAR2, a_datefrom VARCHAR2, a_dateto VARCHAR2, a_selectionid VARCHAR2) RETURN t_nt_grafsales;
  FUNCTION topfive (a_shopid VARCHAR2, a_datefrom VARCHAR2, a_dateto VARCHAR2, a_selectionid VARCHAR2) RETURN CLOB;
  FUNCTION lowfive (a_shopid VARCHAR2, a_datefrom VARCHAR2, a_dateto VARCHAR2, a_selectionid VARCHAR2) RETURN CLOB;
  FUNCTION visitors (a_shopid VARCHAR2, a_datefrom VARCHAR2, a_dateto VARCHAR2, a_selectionid VARCHAR2) RETURN VARCHAR2;
  FUNCTION import_product_data(a_list CLOB) RETURN VARCHAR2;
  --
END;