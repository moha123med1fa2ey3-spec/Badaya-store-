"use client";
import Link from "next/link";
import { useTransition } from "react";
import { Button } from "@/components/ui/button";
import { deleteProduct, duplicateProduct } from "@/lib/actions/products";

export function ProductRowActions({ productId, canDelete }: { productId: string; canDelete: boolean }) {
  const [isPending, startTransition] = useTransition();

  return (
    <div className="flex justify-end gap-2">
      <Link href={`/dashboard/products/${productId}`}>
        <Button variant="secondary">Edit</Button>
      </Link>
      <Button variant="secondary" disabled={isPending} onClick={() => startTransition(() => duplicateProduct(productId))}>
        Duplicate
      </Button>
      {canDelete && (
        <Button
          variant="danger"
          disabled={isPending}
          onClick={() => {
            if (confirm("Delete this product? This cannot be undone.")) {
              startTransition(() => deleteProduct(productId));
            }
          }}
        >
          Delete
        </Button>
      )}
    </div>
  );
}
