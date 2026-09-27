# MerchantOS — Phase 1

A real, working slice of a multi-tenant e-commerce SaaS: authentication, store
onboarding, role-based access control, and a full Products/Categories module —
all wired to a live Supabase (PostgreSQL) backend. No mock data, no fake API:
every screen reads and writes through Supabase with Row Level Security enforcing
tenant isolation.

## What's built (Phase 1)

- **Auth**: sign up, log in, log out, forgot/reset password, email verification
- **Onboarding**: store creation wizard (creates `stores` row + `store_members`
  row with OWNER role)
- **RBAC**: middleware + server-side permission checks using your
  `has_permission_in_store()` / `get_user_role_in_store()` SQL functions.
  Sidebar links and buttons are hidden/shown per the logged-in user's actual
  permissions, and every write is re-checked server-side (never trust the UI).
- **Dashboard overview**: product/category counts pulled live from the DB
- **Products**: full CRUD, search, status filter, pagination, duplicate,
  low-stock highlighting
- **Categories**: full CRUD

## ⚠️ Fixes made to your schema — read before running

`supabase/schema.sql` is your file, unchanged. I added
**`supabase/policies_extra.sql`**, which you must also run, because the
original schema had two issues that would have silently broken the app:

1. **No `auth.users` → `profiles` sync.** Nothing populated `profiles` on
   signup, and almost every table's foreign keys point at `profiles`.
   Added a trigger that inserts a `profiles` row automatically.
2. **Write policies were missing almost everywhere.** Nearly every table
   (`products`, `categories`, `product_variants`, `inventory`,
   `store_members`, `store_settings`, ...) only had a `SELECT` RLS policy.
   With RLS enabled, that means **no one — not even the store owner — could
   insert or update a row** from the client. `policies_extra.sql` adds the
   missing INSERT/UPDATE/DELETE policies, gated by the same
   `has_permission_in_store()` function your schema already defines.

## Setup

1. Create a Supabase project.
2. In the SQL editor, run **`supabase/schema.sql`**, then
   **`supabase/policies_extra.sql`**.
3. Copy `.env.example` to `.env.local` and fill in your project's URL and
   anon key (Project Settings → API).
4. `npm install`
5. `npm run dev` → http://localhost:3000

## Roadmap (not built yet — say which one to build next)

- Orders, order items, order status history + checkout flow
- Payments (providers + transactions)
- Shipping (zones, rates, shipments)
- Returns & refunds
- Customers CRM + addresses + tags
- Coupons & promotions
- Invoices & expenses (profit calculation)
- Employee invite flow + full roles/permissions management UI
- Storefront builder (public-facing store pages)
- Analytics dashboards with charts and date-range filters
- Subscription/billing (plans, Stripe/Paymob integration)
- AI Assistant
- Multi-store switcher for users belonging to more than one store

Each of these is its own real module (DB writes, RLS, permission checks, UI) —
building them one at a time, the same way Products was built here, is what
will actually get you to "production-ready" rather than a shell that looks
finished but doesn't work.
