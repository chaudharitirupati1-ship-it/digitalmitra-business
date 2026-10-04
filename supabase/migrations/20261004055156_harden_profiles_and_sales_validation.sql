-- Applied to the DigitalMitra Business Supabase project as migration 20261004055156.
-- Customers may read their own profile, but only the admin Edge Function may mutate
-- role/status/expiry/business_name through the service role.
drop policy if exists "profiles own" on public.profiles;
create policy "profiles select own" on public.profiles
  for select to authenticated
  using (id = auth.uid());

alter table public.sales
  drop constraint if exists sales_payment_method_check;
alter table public.sales
  add constraint sales_payment_method_check
  check (payment_method in ('Cash','UPI','Card','Credit','Other'));

alter table public.customers
  add column if not exists opening_due numeric not null default 0;

update public.customers c
set opening_due = greatest(
  coalesce(c.due_amount,0)
  - coalesce((
      select sum(s.total)
      from public.sales s
      where s.user_id = c.user_id
        and s.payment_method = 'Credit'
        and lower(trim(s.customer_name)) = lower(trim(c.name))
    ),0)
  + coalesce((
      select sum(cp.amount)
      from public.customer_payments cp
      where cp.customer_id = c.id
    ),0),
  0
);

comment on column public.customers.opening_due is 'Customer balance brought forward before credit sales and recorded payments.';
