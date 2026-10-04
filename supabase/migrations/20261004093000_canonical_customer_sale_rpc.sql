drop function if exists public.create_sale(text, uuid, integer, text);

create or replace function public.create_sale(
  p_customer_id uuid,
  p_customer_name text,
  p_product_id uuid,
  p_quantity integer,
  p_payment_method text
)
returns json
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_product public.products%rowtype;
  v_sale public.sales%rowtype;
  v_total numeric(12,2);
  v_profit numeric(12,2);
  v_customer_id uuid;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  if p_quantity is null or p_quantity <= 0 then raise exception 'Quantity must be greater than zero'; end if;
  if p_payment_method not in ('Cash','UPI','Card','Credit','Other') then raise exception 'Invalid payment method'; end if;

  if p_customer_id is not null then
    select c.id into v_customer_id from public.customers c where c.id=p_customer_id and c.user_id=auth.uid();
    if not found then raise exception 'Customer not found'; end if;
  end if;

  select * into v_product from public.products where id=p_product_id and user_id=auth.uid() for update;
  if not found then raise exception 'Product not found'; end if;
  if v_product.stock < p_quantity then raise exception 'Not enough stock. Available: %',v_product.stock; end if;

  v_total := round(v_product.selling_price*p_quantity,2);
  v_profit := round((v_product.selling_price-v_product.cost_price)*p_quantity,2);
  update public.products set stock=stock-p_quantity where id=v_product.id;

  insert into public.sales(user_id,customer_id,customer_name,product_id,quantity,total,profit,payment_method)
  values(auth.uid(),v_customer_id,coalesce(nullif(trim(p_customer_name),''),'Walk-in Customer'),v_product.id,p_quantity,v_total,v_profit,p_payment_method)
  returning * into v_sale;

  return json_build_object('sale_id',v_sale.id,'total',v_total,'profit',v_profit,'stock_remaining',v_product.stock-p_quantity);
end;
$function$;

revoke execute on function public.create_sale(uuid,text,uuid,integer,text) from public;
revoke execute on function public.create_sale(uuid,text,uuid,integer,text) from anon;
grant execute on function public.create_sale(uuid,text,uuid,integer,text) to authenticated;