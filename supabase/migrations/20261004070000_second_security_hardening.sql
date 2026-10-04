-- Second security hardening pass for DigitalMitra Business.
drop policy if exists "sales own" on public.sales;
create policy "sales select own" on public.sales
  for select to authenticated
  using (user_id = (select auth.uid()));
create policy "sales delete own" on public.sales
  for delete to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists "customer_payments_insert_own" on public.customer_payments;
create policy "customer_payments_insert_own" on public.customer_payments
  for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.customers c
      where c.id = customer_id
        and c.user_id = (select auth.uid())
    )
  );

alter table public.services
  drop constraint if exists services_payment_method_check;
alter table public.services
  add constraint services_payment_method_check
  check (payment_method in ('Cash','UPI','Card','Credit','Other'));

alter table public.services
  drop constraint if exists services_status_check;
alter table public.services
  add constraint services_status_check
  check (status in ('Pending','In Progress','Completed','Cancelled'));

alter table public.services
  drop constraint if exists services_price_check;
alter table public.services
  add constraint services_price_check check (price >= 0);

alter table public.services
  drop constraint if exists services_cost_check;
alter table public.services
  add constraint services_cost_check check (cost >= 0);
