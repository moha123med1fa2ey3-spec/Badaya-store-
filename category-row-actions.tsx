"use client";
import { useTransition } from "react";
import { Button } from "@/components/ui/button";
import { deleteCategory } from "@/lib/actions/categories";

export function CategoryRowActions({ categoryId }: { categoryId: string }) {
  const [isPending, startTransition] = useTransition();
  return (
    <Button
      variant="danger"
      disabled={isPending}
      onClick={() => {
        if (confirm("Delete this category?")) startTransition(() => deleteCategory(categoryId));
      }}
    >
      Delete
    </Button>
  );
}
