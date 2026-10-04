-- Restrict sale RPC to signed-in customers only.
revoke execute on function public.create_sale(uuid,text,uuid,integer,text) from public;
revoke execute on function public.create_sale(uuid,text,uuid,integer,text) from anon;
grant execute on function public.create_sale(uuid,text,uuid,integer,text) to authenticated;
