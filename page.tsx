import { requireStore, hasPermission } from "@/lib/auth";
import { createServerSupabase } from "@/lib/supabase/server";
import { createCategory } from "@/lib/actions/categories";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { CategoryRowActions } from "@/components/products/category-row-actions";

export default async function CategoriesPage() {
  const store = await requireStore();
  const canCreate = await hasPermission(store.id, "products.create");
  const canDelete = await hasPermission(store.id, "products.delete");

  const supabase = createServerSupabase();
  const { data: categories } = await supabase
    .from("categories")
    .select("id, name, slug, status")
    .eq("store_id", store.id)
    .order("name");

  return (
    <div>
      <h1 className="mb-6 text-2xl font-semibold text-slate-900">Categories</h1>

      {canCreate && (
        <form action={createCategory} className="mb-6 flex max-w-md gap-3">
          <Input name="name" placeholder="New category name" required />
          <Button type="submit">Add</Button>
        </form>
      )}

      <div className="overflow-hidden rounded-xl border border-slate-200 bg-white">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 text-left text-slate-500">
            <tr>
              <th className="px-4 py-3">Name</th>
              <th className="px-4 py-3">Slug</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3"></th>
            </tr>
          </thead>
          <tbody>
            {(categories ?? []).map((c) => (
              <tr key={c.id} className="border-t border-slate-100">
                <td className="px-4 py-3 font-medium text-slate-900">{c.name}</td>
                <td className="px-4 py-3 text-slate-500">{c.slug}</td>
                <td className="px-4 py-3 capitalize">{c.status}</td>
                <td className="px-4 py-3 text-right">
                  {canDelete && <CategoryRowActions categoryId={c.id} />}
                </td>
              </tr>
            ))}
            {(!categories || categories.length === 0) && (
              <tr>
                <td colSpan={4} className="px-4 py-10 text-center text-slate-400">No categories yet.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
