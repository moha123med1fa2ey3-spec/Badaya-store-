import { notFound } from "next/navigation";
import { requireStore, requirePermission } from "@/lib/auth";
import { createServerSupabase } from "@/lib/supabase/server";
import { ProductForm } from "@/components/products/product-form";
import { updateProduct } from "@/lib/actions/products";

export default async function EditProductPage({
  params,
  searchParams,
}: {
  params: { id: string };
  searchParams: { error?: string };
}) {
  const store = await requireStore();
  await requirePermission(store.id, "products.update");

  const supabase = createServerSupabase();
  const [{ data: product }, { data: categories }] = await Promise.all([
    supabase.from("products").select("*").eq("id", params.id).eq("store_id", store.id).single(),
    supabase.from("categories").select("id, name").eq("store_id", store.id).order("name"),
  ]);

  if (!product) notFound();

  const boundAction = updateProduct.bind(null, params.id);

  return (
    <div>
      <h1 className="mb-6 text-2xl font-semibold text-slate-900">Edit product</h1>
      <ProductForm
        action={boundAction}
        categories={categories ?? []}
        defaults={product}
        error={searchParams.error}
        submitLabel="Save changes"
      />
    </div>
  );
}
