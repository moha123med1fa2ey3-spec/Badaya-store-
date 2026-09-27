import Link from "next/link";

const links = [
  { href: "/dashboard", label: "Overview", perm: null },
  { href: "/dashboard/products", label: "Products", perm: "products.view" },
  { href: "/dashboard/categories", label: "Categories", perm: "products.view" },
  { href: "/dashboard/settings", label: "Settings", perm: "settings.manage" },
];

export function Sidebar({ storeName, permissions }: { storeName: string; permissions: Set<string> }) {
  return (
    <aside className="w-64 shrink-0 border-r border-slate-200 bg-white p-4">
      <div className="mb-6 px-2">
        <p className="text-xs uppercase tracking-wide text-slate-400">Store</p>
        <p className="truncate font-semibold text-slate-900">{storeName}</p>
      </div>
      <nav className="space-y-1">
        {links
          .filter((l) => !l.perm || permissions.has(l.perm))
          .map((l) => (
            <Link
              key={l.href}
              href={l.href}
              className="block rounded-lg px-3 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 hover:text-slate-900"
            >
              {l.label}
            </Link>
          ))}
      </nav>
    </aside>
  );
}
