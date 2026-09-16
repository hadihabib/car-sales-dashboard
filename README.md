# Car Sales App - GitHub Secrets

هذا المشروع لا يحتوي مفاتيح Supabase داخل الكود.

## 1) إعداد Supabase

شغّل `disable_rls.sql` مرة واحدة من Supabase SQL Editor.

## 2) إضافة المفاتيح إلى GitHub Secrets

داخل Repository:

Settings
→ Secrets and variables
→ Actions
→ New repository secret

أضف:

### SUPABASE_URL
القيمة: Project URL من Supabase.

### SUPABASE_ANON_KEY
القيمة: Publishable key / anon key من Supabase.

لا تستخدم `sb_secret` أو `service_role`.

## 3) بناء APK

Actions
→ Build Android APK
→ Run workflow

بعد النجاح:
Artifacts
→ car-sales-apk
→ app-release.apk
