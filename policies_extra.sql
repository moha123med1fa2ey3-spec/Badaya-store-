-- =====================================================
-- PHASE 1 PATCH — run this AFTER schema.sql
-- Fixes found while reviewing schema.sql:
--   1. profiles had no auth.users -> profiles sync (signup would
--      never populate `profiles`, breaking every FK to it).
--   2. Almost every table only had a SELECT policy. With RLS
--      enabled, that means NOBODY (not even OWNER) could insert,
--      update, or delete a row from the client — the app would
--      look "connected" but every write would silently fail.
-- This file adds the missing INSERT/UPDATE/DELETE policies using
-- the store's own has_permission_in_store() function, and a
-- trigger to create a profile row on signup.
-- =====================================================

-- ---------------------------------------------------
-- 1. Auto-create a profile row when a user signs up
-- ---------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, email_verified)
    VALUES (
        NEW.id,
        NEW.email,
        NEW.raw_user_meta_data->>'full_name',
        NEW.email_confirmed_at IS NOT NULL
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ---------------------------------------------------
-- 2. STORES — allow authenticated users to create a store
--    (they become owner_id = auth.uid())
-- ---------------------------------------------------
DROP POLICY IF EXISTS "Authenticated users can create a store" ON stores;
CREATE POLICY "Authenticated users can create a store"
    ON stores FOR INSERT
    WITH CHECK (owner_id = auth.uid());

-- ---------------------------------------------------
-- 3. STORE_MEMBERS — owner can add the first member (self),
--    and anyone with employees.manage can add/update/remove others
-- ---------------------------------------------------
DROP POLICY IF EXISTS "Owner can add self as member" ON store_members;
CREATE POLICY "Owner can add self as member"
    ON store_members FOR INSERT
    WITH CHECK (
        user_id = auth.uid()
        AND store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid())
    );

DROP POLICY IF EXISTS "Managers can invite members" ON store_members;
CREATE POLICY "Managers can invite members"
    ON store_members FOR INSERT
    WITH CHECK (has_permission_in_store(store_id, 'employees.manage'));

DROP POLICY IF EXISTS "Managers can update members" ON store_members;
CREATE POLICY "Managers can update members"
    ON store_members FOR UPDATE
    USING (has_permission_in_store(store_id, 'employees.manage'));

DROP POLICY IF EXISTS "Managers can remove members" ON store_members;
CREATE POLICY "Managers can remove members"
    ON store_members FOR DELETE
    USING (has_permission_in_store(store_id, 'employees.manage'));

-- ---------------------------------------------------
-- 4. STORE_SETTINGS — write requires settings.manage
-- ---------------------------------------------------
DROP POLICY IF EXISTS "Managers can upsert settings" ON store_settings;
CREATE POLICY "Managers can upsert settings"
    ON store_settings FOR INSERT
    WITH CHECK (has_permission_in_store(store_id, 'settings.manage'));

DROP POLICY IF EXISTS "Managers can update settings" ON store_settings;
CREATE POLICY "Managers can update settings"
    ON store_settings FOR UPDATE
    USING (has_permission_in_store(store_id, 'settings.manage'));

-- ---------------------------------------------------
-- 5. CATEGORIES — products.* permission gates category writes
-- ---------------------------------------------------
DROP POLICY IF EXISTS "Can create categories" ON categories;
CREATE POLICY "Can create categories"
    ON categories FOR INSERT
    WITH CHECK (has_permission_in_store(store_id, 'products.create'));

DROP POLICY IF EXISTS "Can update categories" ON categories;
CREATE POLICY "Can update categories"
    ON categories FOR UPDATE
    USING (has_permission_in_store(store_id, 'products.update'));

DROP POLICY IF EXISTS "Can delete categories" ON categories;
CREATE POLICY "Can delete categories"
    ON categories FOR DELETE
    USING (has_permission_in_store(store_id, 'products.delete'));

-- ---------------------------------------------------
-- 6. PRODUCTS
-- ---------------------------------------------------
DROP POLICY IF EXISTS "Can create products" ON products;
CREATE POLICY "Can create products"
    ON products FOR INSERT
    WITH CHECK (has_permission_in_store(store_id, 'products.create'));

DROP POLICY IF EXISTS "Can update products" ON products;
CREATE POLICY "Can update products"
    ON products FOR UPDATE
    USING (has_permission_in_store(store_id, 'products.update'));

DROP POLICY IF EXISTS "Can delete products" ON products;
CREATE POLICY "Can delete products"
    ON products FOR DELETE
    USING (has_permission_in_store(store_id, 'products.delete'));

-- ---------------------------------------------------
-- 7. PRODUCT_IMAGES (gated through parent product's store)
-- ---------------------------------------------------
DROP POLICY IF EXISTS "Can write product images" ON product_images;
CREATE POLICY "Can write product images"
    ON product_images FOR INSERT
    WITH CHECK (
        product_id IN (
            SELECT id FROM products
            WHERE has_permission_in_store(store_id, 'products.update')
        )
    );

DROP POLICY IF EXISTS "Can update product images" ON product_images;
CREATE POLICY "Can update product images"
    ON product_images FOR UPDATE
    USING (
        product_id IN (
            SELECT id FROM products
            WHERE has_permission_in_store(store_id, 'products.update')
        )
    );

DROP POLICY IF EXISTS "Can delete product images" ON product_images;
CREATE POLICY "Can delete product images"
    ON product_images FOR DELETE
    USING (
        product_id IN (
            SELECT id FROM products
            WHERE has_permission_in_store(store_id, 'products.update')
        )
    );

-- ---------------------------------------------------
-- 8. PRODUCT_VARIANTS
-- ---------------------------------------------------
DROP POLICY IF EXISTS "Can write variants" ON product_variants;
CREATE POLICY "Can write variants"
    ON product_variants FOR INSERT
    WITH CHECK (
        product_id IN (
            SELECT id FROM products
            WHERE has_permission_in_store(store_id, 'products.create')
        )
    );

DROP POLICY IF EXISTS "Can update variants" ON product_variants;
CREATE POLICY "Can update variants"
    ON product_variants FOR UPDATE
    USING (
        product_id IN (
            SELECT id FROM products
            WHERE has_permission_in_store(store_id, 'products.update')
        )
    );

DROP POLICY IF EXISTS "Can delete variants" ON product_variants;
CREATE POLICY "Can delete variants"
    ON product_variants FOR DELETE
    USING (
        product_id IN (
            SELECT id FROM products
            WHERE has_permission_in_store(store_id, 'products.delete')
        )
    );

-- ---------------------------------------------------
-- 9. INVENTORY + INVENTORY_MOVEMENTS
-- ---------------------------------------------------
DROP POLICY IF EXISTS "Can write inventory" ON inventory;
CREATE POLICY "Can write inventory"
    ON inventory FOR INSERT
    WITH CHECK (has_permission_in_store(store_id, 'inventory.update'));

DROP POLICY IF EXISTS "Can update inventory" ON inventory;
CREATE POLICY "Can update inventory"
    ON inventory FOR UPDATE
    USING (has_permission_in_store(store_id, 'inventory.update'));

DROP POLICY IF EXISTS "Can log inventory movements" ON inventory_movements;
CREATE POLICY "Can log inventory movements"
    ON inventory_movements FOR INSERT
    WITH CHECK (has_permission_in_store(store_id, 'inventory.update'));

-- ---------------------------------------------------
-- 10. AUDIT_LOGS — server/service-role writes only from the app;
--     no client-side INSERT policy is added on purpose.
-- ---------------------------------------------------
