"use client";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";

export function Topbar({ role }: { role: string | null }) {
  const router = useRouter();
  const supabase = createClient();

  async function handleLogout() {
    await supabase.auth.signOut();
    router.push("/login");
    router.refresh();
  }

  return (
    <header className="flex items-center justify-between border-b border-slate-200 bg-white px-6 py-3">
      <span className="text-sm text-slate-500">Role: <span className="font-medium text-slate-700">{role ?? "—"}</span></span>
      <Button variant="secondary" onClick={handleLogout}>Log out</Button>
    </header>
  );
}
