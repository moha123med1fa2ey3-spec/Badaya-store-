import { redirect } from "next/navigation";
import { createServerSupabase } from "@/lib/supabase/server";

// Every helper here hits the real database — nothing is hardcoded or mocked.
// Tenant isolation is enforced by RLS + these functions from schema.sql:
//   has_permission_in_store(store_id, permission_name)
//   get_user_role_in_store(store_id)

export async function getCurrentUser() {
  const supabase = createServerSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  return user;
}

export async function requireUser() {
  const user = await getCurrentUser();
  if (!user) redirect("/login");
  return user;
}

/** The first active store this user belongs to. Phase 2 will add a store switcher for multi-store users. */
export async function getCurrentStore() {
  const user = await requireUser();
  const supabase = createServerSupabase();

  const { data: membership } = await supabase
    .from("store_members")
    .select("store_id, stores(*)")
    .eq("user_id", user.id)
    .eq("status", "active")
    .limit(1)
    .maybeSingle();

  if (!membership) return null;
  return membership.stores as unknown as { id: string; name: string; slug: string; currency: string };
}

export async function requireStore() {
  const store = await getCurrentStore();
  if (!store) redirect("/onboarding/create-store");
  return store;
}

export async function hasPermission(storeId: string, permission: string) {
  const supabase = createServerSupabase();
  const { data, error } = await supabase.rpc("has_permission_in_store", {
    p_store_id: storeId,
    p_permission_name: permission,
  });
  if (error) {
    console.error("hasPermission error:", error.message);
    return false;
  }
  return Boolean(data);
}

export async function getUserRole(storeId: string) {
  const supabase = createServerSupabase();
  const { data, error } = await supabase.rpc("get_user_role_in_store", {
    p_store_id: storeId,
  });
  if (error) {
    console.error("getUserRole error:", error.message);
    return null;
  }
  return data as string | null;
}

/** Redirects away if the current user lacks `permission` in `storeId`. Use in server components/actions before any write. */
export async function requirePermission(storeId: string, permission: string) {
  const allowed = await hasPermission(storeId, permission);
  if (!allowed) redirect("/dashboard?error=forbidden");
}
