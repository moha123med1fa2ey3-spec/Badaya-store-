import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Alert } from "@/components/ui/alert";

type Category = { id: string; name: string };
type ProductDefaults = {
  name?: string;
  category_id?: string | null;
  sku?: string | null;
  price?: number;
  compare_price?: number | null;
  cost_price?: number | null;
  stock?: number;
  low_stock_threshold?: number;
  description?: string | null;
  status?: string;
};

export function ProductForm({
  action,
  categories,
  defaults,
  error,
  submitLabel,
}: {
  action: (formData: FormData) => void;
  categories: Category[];
  defaults?: ProductDefaults;
  error?: string;
  submitLabel: string;
}) {
  return (
    <form action={action} className="max-w-2xl space-y-4">
      {error && <Alert>{error}</Alert>}

      <div>
        <Label htmlFor="name">Product name</Label>
        <Input id="name" name="name" required defaultValue={defaults?.name} />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <Label htmlFor="category_id">Category</Label>
          <select
            id="category_id"
            name="category_id"
            defaultValue={defaults?.category_id ?? ""}
            className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
          >
            <option value="">Uncategorized</option>
            {categories.map((c) => (
              <option key={c.id} value={c.id}>{c.name}</option>
            ))}
          </select>
        </div>
        <div>
          <Label htmlFor="sku">SKU</Label>
          <Input id="sku" name="sku" defaultValue={defaults?.sku ?? ""} />
        </div>
      </div>

      <div className="grid grid-cols-3 gap-4">
        <div>
          <Label htmlFor="price">Price</Label>
          <Input id="price" name="price" type="number" step="0.01" min="0" required defaultValue={defaults?.price} />
        </div>
        <div>
          <Label htmlFor="compare_price">Compare-at price</Label>
          <Input id="compare_price" name="compare_price" type="number" step="0.01" min="0" defaultValue={defaults?.compare_price ?? ""} />
        </div>
        <div>
          <Label htmlFor="cost_price">Cost price</Label>
          <Input id="cost_price" name="cost_price" type="number" step="0.01" min="0" defaultValue={defaults?.cost_price ?? ""} />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <Label htmlFor="stock">Stock</Label>
          <Input id="stock" name="stock" type="number" min="0" defaultValue={defaults?.stock ?? 0} />
        </div>
        <div>
          <Label htmlFor="low_stock_threshold">Low stock threshold</Label>
          <Input id="low_stock_threshold" name="low_stock_threshold" type="number" min="0" defaultValue={defaults?.low_stock_threshold ?? 5} />
        </div>
      </div>

      <div>
        <Label htmlFor="status">Status</Label>
        <select
          id="status"
          name="status"
          defaultValue={defaults?.status ?? "draft"}
          className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
        >
          <option value="draft">Draft</option>
          <option value="active">Active</option>
          <option value="archived">Archived</option>
        </select>
      </div>

      <div>
        <Label htmlFor="description">Description</Label>
        <textarea
          id="description"
          name="description"
          rows={4}
          defaultValue={defaults?.description ?? ""}
          className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
        />
      </div>

      <Button type="submit">{submitLabel}</Button>
    </form>
  );
}
