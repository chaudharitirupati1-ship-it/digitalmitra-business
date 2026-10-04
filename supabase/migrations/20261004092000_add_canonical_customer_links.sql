-- Canonical customer linkage for sales and services.
alter table public.sales add column if not exists customer_id uuid references public.customers(id) on delete set null;
alter table public.services add column if not exists customer_id uuid references public.customers(id) on delete set null;

create index if not exists sales_customer_id_idx on public.sales(user_id, customer_id);
create index if not exists services_customer_id_idx on public.services(user_id, customer_id);

update public.sales s
set customer_id = c.id
from public.customers c
where s.customer_id is null
  and s.user_id = c.user_id
  and lower(regexp_replace(trim(s.customer_name), '\s+', ' ', 'g'))
      = lower(regexp_replace(trim(c.name), '\s+', ' ', 'g'))
  and not exists (
    select 1 from public.customers c2
    where c2.user_id = s.user_id
      and lower(regexp_replace(trim(s.customer_name), '\s+', ' ', 'g'))
          = lower(regexp_replace(trim(c2.name), '\s+', ' ', 'g'))
      and c2.id <> c.id
  );

update public.services s
set customer_id = c.id
from public.customers c
where s.customer_id is null
  and s.user_id = c.user_id
  and lower(regexp_replace(trim(s.customer_name), '\s+', ' ', 'g'))
      = lower(regexp_replace(trim(c.name), '\s+', ' ', 'g'))
  and not exists (
    select 1 from public.customers c2
    where c2.user_id = s.user_id
      and lower(regexp_replace(trim(s.customer_name), '\s+', ' ', 'g'))
          = lower(regexp_replace(trim(c2.name), '\s+', ' ', 'g'))
      and c2.id <> c.id
  );