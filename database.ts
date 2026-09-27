// Hand-written types matching supabase/schema.sql (Phase 1 tables).
// Regenerate with `supabase gen types typescript` once the project is linked
// to a real Supabase instance for full type coverage of every table.

export type ProductStatus = "draft" | "active" | "archived";
export type StoreStatus = "active" | "suspended" | "deleted";
export type MemberStatus = "active" | "suspended" | "removed";

export interface Profile {
  id: string;
  email: string;
  full_name: string | null;
  phone: string | null;
  avatar_url: string | null;
  email_verified: boolean;
  created_at: string;
  updated_at: string;
}

export interface Store {
  id: string;
  name: string;
  slug: string;
  logo_url: string | null;
  business_type: string | null;
  country: string;
  currency: string;
  phone: string | null;
  email: string | null;
  address: string | null;
  governorate: string | null;
  city: string | null;
  status: StoreStatus;
  owner_id: string;
  created_at: string;
  updated_at: string;
}

export interface Role {
  id: string;
  name: "OWNER" | "ADMIN" | "MANAGER" | "SALES" | "WAREHOUSE" | "ACCOUNTANT" | "SUPPORT";
  description: string | null;
}

export interface StoreMember {
  id: string;
  store_id: string;
  user_id: string;
  role_id: string;
  status: MemberStatus;
  invited_at: string;
  joined_at: string | null;
}

export interface Category {
  id: string;
  store_id: string;
  parent_id: string | null;
  name: string;
  slug: string;
  description: string | null;
  image_url: string | null;
  sort_order: number;
  status: "active" | "archived";
}

export interface Product {
  id: string;
  store_id: string;
  category_id: string | null;
  name: string;
  slug: string;
  description: string | null;
  short_description: string | null;
  sku: string | null;
  barcode: string | null;
  price: number;
  compare_price: number | null;
  cost_price: number | null;
  stock: number;
  low_stock_threshold: number;
  status: ProductStatus;
  is_featured: boolean;
  created_at: string;
  updated_at: string;
}

export interface ProductVariant {
  id: string;
  product_id: string;
  sku: string | null;
  barcode: string | null;
  price: number | null;
  cost_price: number | null;
  stock: number;
  options: Record<string, string>;
  image_url: string | null;
}

export interface ProductImage {
  id: string;
  product_id: string;
  image_url: string;
  alt_text: string | null;
  sort_order: number;
  is_primary: boolean;
}

export interface Database {
  public: {
    Tables: {
      profiles: { Row: Profile; Insert: Partial<Profile>; Update: Partial<Profile> };
      stores: { Row: Store; Insert: Partial<Store>; Update: Partial<Store> };
      roles: { Row: Role; Insert: Partial<Role>; Update: Partial<Role> };
      store_members: { Row: StoreMember; Insert: Partial<StoreMember>; Update: Partial<StoreMember> };
      categories: { Row: Category; Insert: Partial<Category>; Update: Partial<Category> };
      products: { Row: Product; Insert: Partial<Product>; Update: Partial<Product> };
      product_variants: { Row: ProductVariant; Insert: Partial<ProductVariant>; Update: Partial<ProductVariant> };
      product_images: { Row: ProductImage; Insert: Partial<ProductImage>; Update: Partial<ProductImage> };
    };
  };
}
