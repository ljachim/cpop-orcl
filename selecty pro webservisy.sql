-- orders
 -- co kdyz je ta mnozina empty? v tom pripade nas zajima VSECHNO!! - dodelat

select count(distinct s.id_sale) 
  from cp_sale s, cp_sale_product sp
    where s.id_shop = 21
      and s.sale_date between sysdate-15 and sysdate-10
    and s.id_sale = sp.id_sale
    and sp.id_product in (select p.id_product from cp_product p, selection_product sel where p.productid = sel.productid and sel.id_selection = 21);
    
-- sales

select sum(p.price) 
  from cp_sale s, cp_sale_product sp, cp_product p, selection_product sel 
    where s.id_shop = 21
      and s.sale_date between sysdate-1 and sysdate+10
    and s.id_sale = sp.id_sale
    and p.productid = sel.productid
    and sp.id_product = p.id_product 
    and sel.id_selection = 21;

