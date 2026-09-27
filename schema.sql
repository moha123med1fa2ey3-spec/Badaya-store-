-- =====================================================
-- MERCHANTOS SAAS PLATFORM - PHASE 1
-- Multi-Tenant E-commerce Management System
-- Database: PostgreSQL (Supabase)
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. PROFILES (Users)
-- =====================================================
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    phone TEXT,
    avatar_url TEXT,
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS for profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

-- =====================================================
-- 2. STORES
-- =====================================================
CREATE TABLE IF NOT EXISTS stores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    logo_url TEXT,
    business_type TEXT,
    country TEXT DEFAULT 'EG',
    currency TEXT DEFAULT 'EGP',
    phone TEXT,
    email TEXT,
    address TEXT,
    governorate TEXT,
    city TEXT,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'deleted')),
    owner_id UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for slug lookup
CREATE INDEX IF NOT EXISTS idx_stores_slug ON stores(slug);
CREATE INDEX IF NOT EXISTS idx_stores_owner ON stores(owner_id);

-- RLS for stores
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;

-- Store members can view their stores
DROP POLICY IF EXISTS "Store members can view" ON stores;
CREATE POLICY "Store members can view"
    ON stores FOR SELECT
    USING (
        id IN (
            SELECT store_id FROM store_members 
            WHERE user_id = auth.uid()
        )
        OR owner_id = auth.uid()
    );

-- Only owner can update store
DROP POLICY IF EXISTS "Store owner can update" ON stores;
CREATE POLICY "Store owner can update"
    ON stores FOR UPDATE
    USING (owner_id = auth.uid());

-- =====================================================
-- 3. STORE SETTINGS
-- =====================================================
CREATE TABLE IF NOT EXISTS store_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(store_id)
);

-- RLS
ALTER TABLE store_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Store members can view settings" ON store_settings;
CREATE POLICY "Store members can view settings"
    ON store_settings FOR SELECT
    USING (
        store_id IN (
            SELECT store_id FROM store_members 
            WHERE user_id = auth.uid()
        )
    );

-- =====================================================
-- 4. ROLES
-- =====================================================
CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default roles (idempotent)
INSERT INTO roles (name, description) VALUES
    ('OWNER', 'Store Owner - Full Access'),
    ('ADMIN', 'Administrator - Full Access'),
    ('MANAGER', 'Manager - Limited Access'),
    ('SALES', 'Sales Team - Orders & Customers'),
    ('WAREHOUSE', 'Warehouse - Inventory & Products'),
    ('ACCOUNTANT', 'Accountant - Finance & Reports'),
    ('SUPPORT', 'Support - Orders & Customers')
ON CONFLICT (name) DO NOTHING;

-- =====================================================
-- 5. PERMISSIONS
-- =====================================================
CREATE TABLE IF NOT EXISTS permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    module TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default permissions (idempotent)
INSERT INTO permissions (name, description, module) VALUES
    ('products.view', 'View Products', 'products'),
    ('products.create', 'Create Products', 'products'),
    ('products.update', 'Update Products', 'products'),
    ('products.delete', 'Delete Products', 'products'),
    ('orders.view', 'View Orders', 'orders'),
    ('orders.create', 'Create Orders', 'orders'),
    ('orders.update', 'Update Orders', 'orders'),
    ('orders.cancel', 'Cancel Orders', 'orders'),
    ('orders.refund', 'Process Refunds', 'orders'),
    ('customers.view', 'View Customers', 'customers'),
    ('customers.create', 'Create Customers', 'customers'),
    ('customers.update', 'Update Customers', 'customers'),
    ('inventory.view', 'View Inventory', 'inventory'),
    ('inventory.update', 'Update Inventory', 'inventory'),
    ('analytics.view', 'View Analytics', 'analytics'),
    ('employees.manage', 'Manage Employees', 'employees'),
    ('settings.manage', 'Manage Settings', 'settings'),
    ('subscription.manage', 'Manage Subscription', 'subscription')
ON CONFLICT (name) DO NOTHING;

-- =====================================================
-- 6. ROLE_PERMISSIONS
-- =====================================================
CREATE TABLE IF NOT EXISTS role_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID REFERENCES permissions(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(role_id, permission_id)
);

-- Assign permissions to OWNER role (all permissions)
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.name = 'OWNER'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- =====================================================
-- 7. STORE_MEMBERS (Employees)
-- =====================================================
CREATE TABLE IF NOT EXISTS store_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    role_id UUID REFERENCES roles(id),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'removed')),
    invited_at TIMESTAMPTZ DEFAULT NOW(),
    joined_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(store_id, user_id)
);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_store_members_store ON store_members(store_id);
CREATE INDEX IF NOT EXISTS idx_store_members_user ON store_members(user_id);

-- RLS
ALTER TABLE store_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Store members can view members" ON store_members;
CREATE POLICY "Store members can view members"
    ON store_members FOR SELECT
    USING (
        store_id IN (
            SELECT store_id FROM store_members 
            WHERE user_id = auth.uid()
        )
    );

-- =====================================================
-- 8. CATEGORIES
-- =====================================================
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    slug TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    sort_order INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'archived')),
    meta_title TEXT,
    meta_description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(store_id, slug)
);

CREATE INDEX IF NOT EXISTS idx_categories_store ON categories(store_id);
CREATE INDEX IF NOT EXISTS idx_categories_parent ON categories(parent_id);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Store members can view categories" ON categories;
CREATE POLICY "Store members can view categories"
    ON categories FOR SELECT
    USING (
        store_id IN (
            SELECT store_id FROM store_members 
            WHERE user_id = auth.uid()
        )
    );

-- =====================================================
-- 9. PRODUCTS
-- =====================================================
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    slug TEXT NOT NULL,
    description TEXT,
    short_description TEXT,
    sku TEXT,
    barcode TEXT,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    compare_price DECIMAL(10,2) CHECK (compare_price >= 0),
    cost_price DECIMAL(10,2) CHECK (cost_price >= 0),
    stock INTEGER DEFAULT 0 CHECK (stock >= 0),
    low_stock_threshold INTEGER DEFAULT 5,
    weight DECIMAL(10,2),
    length DECIMAL(10,2),
    width DECIMAL(10,2),
    height DECIMAL(10,2),
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'archived')),
    is_featured BOOLEAN DEFAULT FALSE,
    meta_title TEXT,
    meta_description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(store_id, slug)
);

CREATE INDEX IF NOT EXISTS idx_products_store ON products(store_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_status ON products(status);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Store members can view products" ON products;
CREATE POLICY "Store members can view products"
    ON products FOR SELECT
    USING (
        store_id IN (
            SELECT store_id FROM store_members 
            WHERE user_id = auth.uid()
        )
    );

-- =====================================================
-- 10. PRODUCT_IMAGES
-- =====================================================
CREATE TABLE IF NOT EXISTS product_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    alt_text TEXT,
    sort_order INTEGER DEFAULT 0,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_product_images_product ON product_images(product_id);

ALTER TABLE product_images ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Store members can view product images" ON product_images;
CREATE POLICY "Store members can view product images"
    ON product_images FOR SELECT
    USING (
        product_id IN (
            SELECT p.id FROM products p
            WHERE p.store_id IN (
                SELECT store_id FROM store_members 
                WHERE user_id = auth.uid()
            )
        )
    );

-- =====================================================
-- 11. PRODUCT_VARIANTS
-- =====================================================
CREATE TABLE IF NOT EXISTS product_variants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    sku TEXT,
    barcode TEXT,
    price DECIMAL(10,2) CHECK (price >= 0),
    cost_price DECIMAL(10,2) CHECK (cost_price >= 0),
    stock INTEGER DEFAULT 0 CHECK (stock >= 0),
    options JSONB DEFAULT '{}',
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_product_variants_product ON product_variants(product_id);

ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Store members can view variants" ON product_variants;
CREATE POLICY "Store members can view variants"
    ON product_variants FOR SELECT
    USING (
        product_id IN (
            SELECT p.id FROM products p
            WHERE p.store_id IN (
                SELECT store_id FROM store_members 
                WHERE user_id = auth.uid()
            )
        )
    );

-- =====================================================
-- 12. INVENTORY
-- =====================================================
CREATE TABLE IF NOT EXISTS inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    variant_id UUID REFERENCES product_variants(id) ON DELETE CASCADE,
    quantity INTEGER DEFAULT 0 CHECK (quantity >= 0),
    reserved INTEGER DEFAULT 0 CHECK (reserved >= 0),
    available INTEGER GENERATED ALWAYS AS (quantity - reserved) STORED,
    last_counted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(store_id, product_id, variant_id)
);

CREATE INDEX IF NOT EXISTS idx_inventory_store ON inventory(store_id);

ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Store members can view inventory" ON inventory;
CREATE POLICY "Store members can view inventory"
    ON inventory FOR SELECT
    USING (
        store_id IN (
            SELECT store_id FROM store_members 
            WHERE user_id = auth.uid()
        )
    );

-- =====================================================
-- 13. INVENTORY_MOVEMENTS
-- =====================================================
CREATE TABLE IF NOT EXISTS inventory_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    variant_id UUID REFERENCES product_variants(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('sale', 'return', 'purchase', 'adjustment', 'damage', 'manual')),
    reason TEXT,
    reference_type TEXT,
    reference_id UUID,
    user_id UUID REFERENCES profiles(id),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_inventory_movements_store ON inventory_movements(store_id);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_product ON inventory_movements(product_id);

ALTER TABLE inventory_movements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Store members can view movements" ON inventory_movements;
CREATE POLICY "Store members can view movements"
    ON inventory_movements FOR SELECT
    USING (
        store_id IN (
            SELECT store_id FROM store_members 
            WHERE user_id = auth.uid()
        )
    );

-- =====================================================
-- 14. AUDIT_LOGS
-- =====================================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id),
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id UUID,
    old_value JSONB,
    new_value JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_store ON audit_logs(store_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs(entity_type, entity_id);

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Store admins can view audit logs" ON audit_logs;
CREATE POLICY "Store admins can view audit logs"
    ON audit_logs FOR SELECT
    USING (
        store_id IN (
            SELECT store_id FROM store_members sm
            WHERE sm.user_id = auth.uid()
            AND sm.role_id IN (
                SELECT id FROM roles WHERE name IN ('OWNER', 'ADMIN')
            )
        )
    );

-- =====================================================
-- 15. STORE DOMAINS
-- =====================================================
CREATE TABLE IF NOT EXISTS store_domains (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
    domain TEXT UNIQUE NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'failed')),
    is_primary BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_store_domains_store ON store_domains(store_id);

ALTER TABLE store_domains ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Store members can view domains" ON store_domains;
CREATE POLICY "Store members can view domains"
    ON store_domains FOR SELECT
    USING (
        store_id IN (
            SELECT store_id FROM store_members 
            WHERE user_id = auth.uid()
        )
    );

-- =====================================================
-- FUNCTIONS & TRIGGERS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_stores_updated_at ON stores;
CREATE TRIGGER update_stores_updated_at BEFORE UPDATE ON stores
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_store_settings_updated_at ON store_settings;
CREATE TRIGGER update_store_settings_updated_at BEFORE UPDATE ON store_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_store_members_updated_at ON store_members;
CREATE TRIGGER update_store_members_updated_at BEFORE UPDATE ON store_members
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_categories_updated_at ON categories;
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_products_updated_at ON products;
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_product_variants_updated_at ON product_variants;
CREATE TRIGGER update_product_variants_updated_at BEFORE UPDATE ON product_variants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_inventory_updated_at ON inventory;
CREATE TRIGGER update_inventory_updated_at BEFORE UPDATE ON inventory
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_store_domains_updated_at ON store_domains;
CREATE TRIGGER update_store_domains_updated_at BEFORE UPDATE ON store_domains
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to check if user has permission in a store
CREATE OR REPLACE FUNCTION has_permission_in_store(
    p_store_id UUID,
    p_permission_name TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    v_has_permission BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1
        FROM store_members sm
        JOIN role_permissions rp ON sm.role_id = rp.role_id
        JOIN permissions p ON rp.permission_id = p.id
        WHERE sm.store_id = p_store_id
        AND sm.user_id = auth.uid()
        AND sm.status = 'active'
        AND p.name = p_permission_name
    ) INTO v_has_permission;

    RETURN COALESCE(v_has_permission, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's role in a store
CREATE OR REPLACE FUNCTION get_user_role_in_store(p_store_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_role_name TEXT;
BEGIN
    SELECT r.name INTO v_role_name
    FROM store_members sm
    JOIN roles r ON sm.role_id = r.id
    WHERE sm.store_id = p_store_id
    AND sm.user_id = auth.uid()
    AND sm.status = 'active';

    RETURN v_role_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- EGYPT GOVERNORATES (Reference Data)
-- =====================================================
CREATE TABLE IF NOT EXISTS egypt_governorates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_ar TEXT NOT NULL,
    name_en TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO egypt_governorates (name_ar, name_en) VALUES
    ('القاهرة', 'Cairo'),
    ('الجيزة', 'Giza'),
    ('الإسكندرية', 'Alexandria'),
    ('الدقهلية', 'Dakahlia'),
    ('البحر الأحمر', 'Red Sea'),
    ('البحيرة', 'Beheira'),
    ('الفيوم', 'Fayoum'),
    ('الغربية', 'Gharbiya'),
    ('أسيوط', 'Asyut'),
    ('الإسماعيلية', 'Ismailia'),
    ('المنوفية', 'Menofia'),
    ('المنيا', 'Minya'),
    ('الشرقية', 'Sharqia'),
    ('الوادي الجديد', 'New Valley'),
    ('السويس', 'Suez'),
    ('أسوان', 'Aswan'),
    ('جنوب سيناء', 'South Sinai'),
    ('كفر الشيخ', 'Kafr El Sheikh'),
    ('مطروح', 'Matrouh'),
    ('الأقصر', 'Luxor'),
    ('بورسعيد', 'Port Said'),
    ('دمياط', 'Damietta'),
    ('شمال سيناء', 'North Sinai'),
    ('سوهاج', 'Sohag'),
    ('القليوبية', 'Qalyubia')
ON CONFLICT DO NOTHING;

-- =====================================================
-- END OF PHASE 1 SCHEMA
-- =====================================================
