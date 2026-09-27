"use server";
import { revalidatePath } from "next/cache";
import { requireStore, requirePermission } from "@/lib/auth";
import { createServerSupabase } from "@/lib/supabase/server";

function slugify(text: string) {
  return text.toLowerCase().trim().replace(/[^a-z0-9\u0600-\u06FF]+/g, "-").replace(/(^-|-$)/g, "");
}

export async function createCategory(formData: FormData) {
  const store = await requireStore();
  await requirePermission(store.id, "products.create");
  const supabase = createServerSupabase();

  const name = String(formData.get("name") ?? "").trim();
  if (!name) return;

  await supabase.from("categories").insert({
    store_id: store.id,
    name,
    slug: `${slugify(name)}-${Date.now().toString(36)}`,
  });

  revalidatePath("/dashboard/categories");
}

export async function deleteCategory(categoryId: string) {
  const store = await requireStore();
  await requirePermission(store.id, "products.delete");
  const supabase = createServerSupabase();

  await supabase.from("categories").delete().eq("id", categoryId).eq("store_id", store.id);
  revalidatePath("/dashboard/categories");
}
