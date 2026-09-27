export function Alert({ type = "error", children }: { type?: "error" | "success"; children: React.ReactNode }) {
  const styles = type === "error" ? "bg-red-50 text-red-700 border-red-200" : "bg-green-50 text-green-700 border-green-200";
  return <div className={`rounded-lg border px-4 py-2 text-sm ${styles}`}>{children}</div>;
}
