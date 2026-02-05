export default function AccountLoading() {
  return (
    <div className="min-h-screen bg-zinc-50 dark:bg-zinc-900">
      <header className="border-b border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-950">
        <div className="mx-auto max-w-4xl px-6 py-4">
          <div className="h-6 w-48 animate-pulse rounded bg-zinc-200 dark:bg-zinc-700" />
          <div className="mt-2 h-4 w-64 animate-pulse rounded bg-zinc-100 dark:bg-zinc-800" />
        </div>
      </header>
      <main className="mx-auto max-w-4xl px-6 py-8">
        <div className="space-y-6">
          {/* Account header skeleton */}
          <div className="flex items-center justify-between">
            <div>
              <div className="h-6 w-40 animate-pulse rounded bg-zinc-200 dark:bg-zinc-700" />
              <div className="mt-2 h-4 w-24 animate-pulse rounded bg-zinc-100 dark:bg-zinc-800" />
            </div>
            <div className="h-6 w-24 animate-pulse rounded-full bg-zinc-200 dark:bg-zinc-700" />
          </div>

          {/* Content skeleton */}
          <div className="rounded-lg border border-zinc-200 bg-white p-6 dark:border-zinc-700 dark:bg-zinc-800">
            <div className="h-6 w-32 animate-pulse rounded bg-zinc-200 dark:bg-zinc-700" />
            <div className="mt-4 grid gap-4 sm:grid-cols-2">
              {[...Array(6)].map((_, i) => (
                <div key={i}>
                  <div className="h-4 w-20 animate-pulse rounded bg-zinc-100 dark:bg-zinc-800" />
                  <div className="mt-1 h-5 w-32 animate-pulse rounded bg-zinc-200 dark:bg-zinc-700" />
                </div>
              ))}
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
