create extension if not exists pgcrypto;
create or replace function public.set_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end; $$;

create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text, timezone text not null default 'Asia/Taipei', currency text not null default 'USD',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path='' as $$
begin insert into public.profiles(id,display_name) values(new.id,coalesce(new.raw_user_meta_data->>'name',new.raw_user_meta_data->>'full_name')); return new; end; $$;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create table public.instruments (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 symbol text not null, name text, asset_class text not null default 'equity' check(asset_class in ('equity','etf','option','future','forex','crypto','other')),
 exchange text, quote_currency text not null default 'USD', notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(user_id,symbol)
);
create table public.trade_plans (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 instrument_id uuid not null references public.instruments(id), side text not null check(side in ('buy','sell')),
 status text not null default 'draft' check(status in ('draft','active','completed','cancelled')),
 planned_entry_price numeric(24,8) check(planned_entry_price is null or planned_entry_price>0),
 planned_quantity numeric(24,8) check(planned_quantity is null or planned_quantity>0), planned_at timestamptz, thesis text, risk_notes text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.import_batches (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 source_name text not null, file_path text, status text not null default 'pending' check(status in ('pending','completed','failed')),
 row_count integer check(row_count is null or row_count>=0), imported_at timestamptz, notes text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.executions (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 instrument_id uuid not null references public.instruments(id), trade_plan_id uuid references public.trade_plans(id), import_batch_id uuid references public.import_batches(id),
 side text not null check(side in ('buy','sell')), executed_at timestamptz not null,
 quantity numeric(24,8) not null check(quantity>0), price numeric(24,8) not null check(price>0), fees numeric(24,8) not null default 0 check(fees>=0),
 currency text not null default 'USD', external_ref text, notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.reviews (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 trade_plan_id uuid references public.trade_plans(id), instrument_id uuid references public.instruments(id), reviewed_at timestamptz not null default now(),
 summary text not null, process_rating smallint check(process_rating is null or process_rating between 1 and 5), emotion text, what_went_well text, what_to_improve text, next_time text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), check(trade_plan_id is not null or instrument_id is not null)
);
create table public.review_insights (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 review_id uuid not null references public.reviews(id), category text not null default 'lesson', content text not null, source text not null default 'user',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create index instruments_user_symbol_idx on public.instruments(user_id,symbol);
create index trade_plans_user_created_idx on public.trade_plans(user_id,created_at desc);
create index trade_plans_instrument_idx on public.trade_plans(instrument_id);
create index import_batches_user_created_idx on public.import_batches(user_id,created_at desc);
create index executions_user_time_idx on public.executions(user_id,executed_at desc);
create index executions_instrument_time_idx on public.executions(instrument_id,executed_at desc);
create index executions_plan_idx on public.executions(trade_plan_id);
create index executions_batch_idx on public.executions(import_batch_id);
create index reviews_user_time_idx on public.reviews(user_id,reviewed_at desc);
create index reviews_plan_idx on public.reviews(trade_plan_id);
create index review_insights_user_created_idx on public.review_insights(user_id,created_at desc);
create index review_insights_review_idx on public.review_insights(review_id);

create trigger profiles_updated before update on public.profiles for each row execute function public.set_updated_at();
create trigger instruments_updated before update on public.instruments for each row execute function public.set_updated_at();
create trigger trade_plans_updated before update on public.trade_plans for each row execute function public.set_updated_at();
create trigger import_batches_updated before update on public.import_batches for each row execute function public.set_updated_at();
create trigger executions_updated before update on public.executions for each row execute function public.set_updated_at();
create trigger reviews_updated before update on public.reviews for each row execute function public.set_updated_at();
create trigger insights_updated before update on public.review_insights for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.instruments enable row level security;
alter table public.trade_plans enable row level security;
alter table public.import_batches enable row level security;
alter table public.executions enable row level security;
alter table public.reviews enable row level security;
alter table public.review_insights enable row level security;

create policy profiles_select on public.profiles for select to authenticated using(id=(select auth.uid()));
create policy profiles_insert on public.profiles for insert to authenticated with check(id=(select auth.uid()));
create policy profiles_update on public.profiles for update to authenticated using(id=(select auth.uid())) with check(id=(select auth.uid()));
create policy profiles_delete on public.profiles for delete to authenticated using(id=(select auth.uid()));

create policy instruments_select on public.instruments for select to authenticated using(user_id=(select auth.uid()));
create policy instruments_insert on public.instruments for insert to authenticated with check(user_id=(select auth.uid()));
create policy instruments_update on public.instruments for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy instruments_delete on public.instruments for delete to authenticated using(user_id=(select auth.uid()));

create policy plans_select on public.trade_plans for select to authenticated using(user_id=(select auth.uid()));
create policy plans_insert on public.trade_plans for insert to authenticated with check(user_id=(select auth.uid()));
create policy plans_update on public.trade_plans for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy plans_delete on public.trade_plans for delete to authenticated using(user_id=(select auth.uid()));

create policy batches_select on public.import_batches for select to authenticated using(user_id=(select auth.uid()));
create policy batches_insert on public.import_batches for insert to authenticated with check(user_id=(select auth.uid()));
create policy batches_update on public.import_batches for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy batches_delete on public.import_batches for delete to authenticated using(user_id=(select auth.uid()));

create policy executions_select on public.executions for select to authenticated using(user_id=(select auth.uid()));
create policy executions_insert on public.executions for insert to authenticated with check(user_id=(select auth.uid()));
-- No UPDATE or DELETE policy: ordinary users cannot edit or delete original fills.

create policy reviews_select on public.reviews for select to authenticated using(user_id=(select auth.uid()));
create policy reviews_insert on public.reviews for insert to authenticated with check(user_id=(select auth.uid()));
create policy reviews_update on public.reviews for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy reviews_delete on public.reviews for delete to authenticated using(user_id=(select auth.uid()));

create policy insights_select on public.review_insights for select to authenticated using(user_id=(select auth.uid()));
create policy insights_insert on public.review_insights for insert to authenticated with check(user_id=(select auth.uid()));
create policy insights_update on public.review_insights for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy insights_delete on public.review_insights for delete to authenticated using(user_id=(select auth.uid()));

insert into storage.buckets(id,name,public) values('trade-journal-private','trade-journal-private',false) on conflict(id) do nothing;
create policy trade_files_select on storage.objects for select to authenticated using(bucket_id='trade-journal-private' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy trade_files_insert on storage.objects for insert to authenticated with check(bucket_id='trade-journal-private' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy trade_files_delete on storage.objects for delete to authenticated using(bucket_id='trade-journal-private' and (storage.foldername(name))[1]=(select auth.uid())::text);


-- Composite ownership constraints prevent a user's rows from referencing another user's records.
alter table public.instruments add constraint instruments_id_user_unique unique(id,user_id);
alter table public.trade_plans add constraint trade_plans_id_user_unique unique(id,user_id);
alter table public.import_batches add constraint import_batches_id_user_unique unique(id,user_id);
alter table public.reviews add constraint reviews_id_user_unique unique(id,user_id);
alter table public.trade_plans add constraint plans_instrument_owner_fk foreign key(instrument_id,user_id) references public.instruments(id,user_id);
alter table public.executions add constraint executions_instrument_owner_fk foreign key(instrument_id,user_id) references public.instruments(id,user_id);
alter table public.executions add constraint executions_plan_owner_fk foreign key(trade_plan_id,user_id) references public.trade_plans(id,user_id);
alter table public.executions add constraint executions_batch_owner_fk foreign key(import_batch_id,user_id) references public.import_batches(id,user_id);
alter table public.reviews add constraint reviews_instrument_owner_fk foreign key(instrument_id,user_id) references public.instruments(id,user_id);
alter table public.reviews add constraint reviews_plan_owner_fk foreign key(trade_plan_id,user_id) references public.trade_plans(id,user_id);
alter table public.review_insights add constraint insights_review_owner_fk foreign key(review_id,user_id) references public.reviews(id,user_id);
