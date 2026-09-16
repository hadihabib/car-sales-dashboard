-- شغّل هذا مرة واحدة في Supabase > SQL Editor
-- هذه النسخة لا تستخدم تسجيل دخول.

alter table public.transactions disable row level security;
alter table public.merchants disable row level security;
alter table public.merchant_ledger disable row level security;
