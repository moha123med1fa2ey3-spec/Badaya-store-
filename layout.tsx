import { requireStore, getUserRole } from "@/lib/auth";
import { createServerSupabase } from "@/lib/supabase/server";
import { Sidebar } from "@/components/dashboard/sidebar";
import { Topbar } from "@/components/dashboard/topbar";

async function getPermissionSet(storeId: string, roleName: string | null) {
  if (!roleName) return new Set<string>();
  const supabase = createServerSupabase();
  const { data } = await supabase
    .from("role_permissions")
    .select("permissions(name), roles!inner(name)")
    .eq("roles.name", roleName);

  const names = (data ?? [])
    .map((row: any) => row.permissions?.name)
    .filter(Boolean) as string[];
  return new Set(names);
}

export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  const store = await requireStore();
  const role = await getUserRole(store.id);
  const permissions = await getPermissionSet(store.id, role);

  return (
    <div className="flex min-h-screen bg-slate-50">
      <Sidebar storeName={store.name} permissions={permissions} />
      <div className="flex-1">
        <Topbar role={role} />
        <main className="p-6">{children}</main>
      </div>
    </div>
  );
}
