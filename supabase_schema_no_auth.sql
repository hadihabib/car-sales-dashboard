create table if not exists public.transactions (
    id bigint generated always as identity primary key,
    transaction_type text check (transaction_type in ('sale', 'return')),
    customer_name text,
    car_make text,
    car_model text,
    part_name text,
    part_brand text,
    part_condition text,
    quantity numeric check (quantity is null or quantity > 0),
    unit_price numeric,
    total_price numeric check (total_price is null or total_price >= 0),
    currency text,
    payment_method text,
    amount_paid numeric,
    related_sale_id bigint references public.transactions(id),
    notes text,
    original_text text,
    status text check (status in ('confirmed', 'cancelled')),
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

create table if not exists public.merchants (
    id bigint generated always as identity primary key,
    name text not null unique,
    phone text,
    notes text,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.merchant_ledger (
    id bigint generated always as identity primary key,
    merchant_id bigint not null references public.merchants(id) on delete restrict,
    movement_type text not null check (
      movement_type in (
        'i_paid_for_him',
        'he_paid_for_me',
        'i_collected_for_him',
        'he_collected_for_me',
        'invoice_from_him',
        'invoice_to_him',
        'cash_to_him',
        'cash_from_him',
        'manual_receivable',
        'manual_payable'
      )
    ),
    balance_effect smallint not null check (balance_effect in (-1, 1)),
    amount numeric not null check (amount > 0),
    currency text not null default 'SYP',
    movement_date date not null default current_date,
    counterparty text,
    reference text,
    notes text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists idx_transactions_created_at
    on public.transactions(created_at desc);

create index if not exists idx_merchant_ledger_merchant
    on public.merchant_ledger(merchant_id);

alter table public.transactions disable row level security;
alter table public.merchants disable row level security;
alter table public.merchant_ledger disable row level security;

grant usage on schema public to anon, authenticated;

grant select, insert, update, delete
on public.transactions,
   public.merchants,
   public.merchant_ledger
to anon, authenticated;

grant usage, select
on all sequences in schema public
to anon, authenticated;
