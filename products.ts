"use server";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { requireStore, requirePermission } from "@/lib/auth";
import { createServerSupabase } from "@/lib/supabase/server";

function slugify(text: string) {
  return text.toLowerCase().trim().replace(/[^a-z0-9\u0600-\u06FF]+/g, "-").replace(/(^-|-$)/g, "");
}

export async function createProduct(formData: FormData) {
  const store = await requireStore();
  await requirePermission(store.id, "products.create");
  const supabase = createServerSupabase();

  const name = String(formData.get("name") ?? "").trim();
  const price = Number(formData.get("price") ?? 0);
  if (!name || price < 0) {
    redirect("/dashboard/products/new?error=invalid_input");
  }

  const payload = {
    store_id: store.id,
    name,
    slug: `${slugify(name)}-${Date.now().toString(36)}`,
    category_id: (formData.get("category_id") as string) || null,
    sku: (formData.get("sku") as string) || null,
    price,
    compare_price: formData.get("compare_price") ? Number(formData.get("compare_price")) : null,
    cost_price: formData.get("cost_price") ? Number(formData.get("cost_price")) : null,
    stock: Number(formData.get("stock") ?? 0),
    low_stock_threshold: Number(formData.get("low_stock_threshold") ?? 5),
    description: (formData.get("description") as string) || null,
    status: (formData.get("status") as string) || "draft",
  };

  const { error } = await supabase.from("products").insert(payload);
  if (error) {
    redirect(`/dashboard/products/new?error=${encodeURIComponent(error.message)}`);
  }

  revalidatePath("/dashboard/products");
  redirect("/dashboard/products");
}

export async function updateProduct(productId: string, formData: FormData) {
  const store = await requireStore();
  await requirePermission(store.id, "products.update");
  const supabase = createServerSupabase();

  const payload = {
    name: String(formData.get("name") ?? "").trim(),
    category_id: (formData.get("category_id") as string) || null,
    sku: (formData.get("sku") as string) || null,
    price: Number(formData.get("price") ?? 0),
    compare_price: formData.get("compare_price") ? Number(formData.get("compare_price")) : null,
    cost_price: formData.get("cost_price") ? Number(formData.get("cost_price")) : null,
    stock: Number(formData.get("stock") ?? 0),
    low_stock_threshold: Number(formData.get("low_stock_threshold") ?? 5),
    description: (formData.get("description") as string) || null,
    status: (formData.get("status") as string) || "draft",
  };

  // store_id filter enforces tenant scoping even though RLS already guarantees it server-side
  const { error } = await supabase.from("products").update(payload).eq("id", productId).eq("store_id", store.id);
  if (error) {
    redirect(`/dashboard/products/${productId}?error=${encodeURIComponent(error.message)}`);
  }

  revalidatePath("/dashboard/products");
  redirect("/dashboard/products");
}

export async function deleteProduct(productId: string) {
  const store = await requireStore();
  await requirePermission(store.id, "products.delete");
  const supabase = createServerSupabase();

  await supabase.from("products").delete().eq("id", productId).eq("store_id", store.id);
  revalidatePath("/dashboard/products");
}

export async function duplicateProduct(productId: string) {
  const store = await requireStore();
  await requirePermission(store.id, "products.create");
  const supabase = createServerSupabase();

  const { data: original } = await supabase.from("products").select("*").eq("id", productId).eq("store_id", store.id).single();
  if (!original) return;

  const { id, created_at, updated_at, slug, ...rest } = original as any;
  await supabase.from("products").insert({
    ...rest,
    name: `${original.name} (Copy)`,
    slug: `${slugify(original.name)}-copy-${Date.now().toString(36)}`,
    status: "draft",
  });

  revalidatePath("/dashboard/products");
}
