-- Market Deals database schema. Run in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Market Deals member',
  avatar_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.listings (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 3 and 90),
  category text not null,
  price numeric(12,2) not null check (price > 0),
  description text default '',
  image_url text,
  status text not null default 'available' check (status in ('available','reserved','sold')),
  buyer_id uuid references public.profiles(id),
  buyer_public_name text,
  buyer_display_consent boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists listings_search_idx on public.listings using gin(to_tsvector('english', title || ' ' || coalesce(description,'')));
create index if not exists listings_status_idx on public.listings(status);
create index if not exists listings_category_idx on public.listings(category);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid references public.listings(id) on delete set null,
  buyer_id uuid not null references public.profiles(id),
  seller_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  unique(listing_id,buyer_id,seller_id),
  check (buyer_id <> seller_id)
);
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id),
  body text not null check (char_length(body) between 1 and 3000),
  created_at timestamptz not null default now()
);
create index if not exists messages_conversation_idx on public.messages(conversation_id,created_at);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null unique references public.listings(id) on delete cascade,
  reviewer_id uuid not null references public.profiles(id),
  seller_id uuid not null references public.profiles(id),
  rating int not null check (rating between 1 and 5),
  comment text default '',
  created_at timestamptz not null default now(),
  check (reviewer_id <> seller_id)
);

-- Create profile rows automatically when someone signs up.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.profiles(id,display_name)
  values(new.id,coalesce(new.raw_user_meta_data->>'display_name','Market Deals member'));
  return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.listings enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.reviews enable row level security;

create policy "Profiles are publicly viewable" on public.profiles for select using (true);
create policy "Users update own profile" on public.profiles for update using (auth.uid()=id) with check(auth.uid()=id);
create policy "Listings visible to everyone" on public.listings for select using (true);
create policy "Signed-in users create own listings" on public.listings for insert to authenticated with check(auth.uid()=seller_id);
create policy "Sellers update own listings" on public.listings for update to authenticated using(auth.uid()=seller_id) with check(auth.uid()=seller_id);
create policy "Sellers delete own listings" on public.listings for delete to authenticated using(auth.uid()=seller_id);
create policy "Conversation members can view" on public.conversations for select to authenticated using(auth.uid()=buyer_id or auth.uid()=seller_id);
create policy "Buyer creates conversation" on public.conversations for insert to authenticated with check(auth.uid()=buyer_id);
create policy "Conversation members view messages" on public.messages for select to authenticated using(exists(select 1 from public.conversations c where c.id=conversation_id and (c.buyer_id=auth.uid() or c.seller_id=auth.uid())));
create policy "Conversation members send messages" on public.messages for insert to authenticated with check(sender_id=auth.uid() and exists(select 1 from public.conversations c where c.id=conversation_id and (c.buyer_id=auth.uid() or c.seller_id=auth.uid())));
create policy "Reviews are public" on public.reviews for select using(true);
create policy "Buyer reviews a completed sale" on public.reviews for insert to authenticated with check(
 reviewer_id=auth.uid() and exists(select 1 from public.listings l where l.id=listing_id and l.status='sold' and l.buyer_id=auth.uid() and l.seller_id=reviews.seller_id)
);

-- Enable Realtime for messages in Supabase Dashboard > Database > Publications if not enabled automatically.
