-- Final production hardening for DigitalMitra Business.
-- Keep auth.uid() wrapped in SELECT for RLS init-plan performance.
drop policy if exists "profiles select own" on public.profiles;
create policy "profiles select own" on public.profiles
  for select to authenticated
  using (id = (select auth.uid()));

-- Validate customer payment methods at the database boundary.
alter table public.customer_payments
  drop constraint if exists customer_payments_payment_method_check;
alter table public.customer_payments
  add constraint customer_payments_payment_method_check
  check (payment_method in ('Cash','UPI','Card','Other'));

-- Prevent invalid product economics/inventory values.
alter table public.products
  drop constraint if exists products_cost_price_check;
alter table public.products
  add constraint products_cost_price_check check (cost_price >= 0);

alter table public.products
  drop constraint if exists products_selling_price_check;
alter table public.products
  add constraint products_selling_price_check check (selling_price >= 0);

alter table public.products
  drop constraint if exists products_stock_check;
alter table public.products
  add constraint products_stock_check check (stock >= 0);

alter table public.products
  drop constraint if exists products_reorder_level_check;
alter table public.products
  add constraint products_reorder_level_check check (reorder_level >= 0);
