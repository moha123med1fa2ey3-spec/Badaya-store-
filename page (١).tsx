"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Alert } from "@/components/ui/alert";
import { Card } from "@/components/ui/card";

function slugify(text: string) {
  return text
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\u0600-\u06FF]+/g, "-")
    .replace(/(^-|-$)/g, "");
}

export default function CreateStorePage() {
  const router = useRouter();
  const supabase = createClient();
  const [name, setName] = useState("");
  const [currency, setCurrency] = useState("EGP");
  const [country, setCountry] = useState("EG");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);

    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      setError("Session expired. Please log in again.");
      setLoading(false);
      return;
    }

    // 1. Create the store — RLS requires owner_id = auth.uid()
    const { data: store, error: storeError } = await supabase
      .from("stores")
      .insert({ name, slug: `${slugify(name)}-${Date.now().toString(36)}`, currency, country, owner_id: user.id })
      .select()
      .single();

    if (storeError || !store) {
      setError(storeError?.message ?? "Could not create store.");
      setLoading(false);
      return;
    }

    // 2. Look up the OWNER role id
    const { data: ownerRole, error: roleError } = await supabase
      .from("roles")
      .select("id")
      .eq("name", "OWNER")
      .single();

    if (roleError || !ownerRole) {
      setError("Store created, but the OWNER role is missing. Check that schema.sql ran fully.");
      setLoading(false);
      return;
    }

    // 3. Add the creator as an active OWNER member of their own store
    const { error: memberError } = await supabase.from("store_members").insert({
      store_id: store.id,
      user_id: user.id,
      role_id: ownerRole.id,
      status: "active",
      joined_at: new Date().toISOString(),
    });

    setLoading(false);
    if (memberError) {
      setError(memberError.message);
      return;
    }

    router.push("/dashboard");
    router.refresh();
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-50 px-4">
      <Card className="w-full max-w-md">
        <h1 className="mb-1 text-xl font-semibold text-slate-900">Create your store</h1>
        <p className="mb-6 text-sm text-slate-500">This takes less than a minute.</p>
        <form onSubmit={handleSubmit} className="space-y-4">
          {error && <Alert>{error}</Alert>}
          <div>
            <Label htmlFor="name">Store name</Label>
            <Input id="name" required value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Nour Boutique" />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <Label htmlFor="country">Country</Label>
              <Input id="country" value={country} onChange={(e) => setCountry(e.target.value)} />
            </div>
            <div>
              <Label htmlFor="currency">Currency</Label>
              <Input id="currency" value={currency} onChange={(e) => setCurrency(e.target.value)} />
            </div>
          </div>
          <Button type="submit" disabled={loading} className="w-full">
            {loading ? "Creating store…" : "Create store"}
          </Button>
        </form>
      </Card>
    </div>
  );
}
