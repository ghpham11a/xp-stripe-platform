"use client";

import type { Account } from "@/lib/types";

interface AccountCardProps {
  account: Account;
  onDelete: () => void;
  deleting: boolean;
}

export function AccountCard({ account, onDelete, deleting }: AccountCardProps) {
  return (
    <div className="rounded-lg border border-zinc-200 bg-white p-6 shadow-sm dark:border-zinc-700 dark:bg-zinc-800">
      <div className="flex items-start justify-between">
        <div>
          <h2 className="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
            {account.display_name || "Unnamed Account"}
          </h2>
          <p className="text-sm text-zinc-500 dark:text-zinc-400">
            {account.email}
          </p>
          <p className="mt-1 font-mono text-xs text-zinc-400 dark:text-zinc-500">
            {account.id}
          </p>
        </div>
        <button
          onClick={onDelete}
          disabled={deleting}
          className="rounded px-3 py-1 text-sm text-red-600 hover:bg-red-50 focus:outline-none focus:ring-2 focus:ring-red-500 disabled:opacity-50 dark:text-red-400 dark:hover:bg-red-900/20"
        >
          {deleting ? "Deleting..." : "Delete"}
        </button>
      </div>

      <div className="mt-4 grid grid-cols-2 gap-4">
        <div className="rounded-lg bg-zinc-50 p-3 dark:bg-zinc-700/50">
          <p className="text-xs font-medium uppercase text-zinc-500 dark:text-zinc-400">
            Customer
          </p>
          <p className={`text-sm font-semibold ${account.is_customer ? "text-green-600" : "text-amber-600"}`}>
            {account.is_customer ? "Enabled" : "Not Configured"}
          </p>
        </div>
        <div className="rounded-lg bg-zinc-50 p-3 dark:bg-zinc-700/50">
          <p className="text-xs font-medium uppercase text-zinc-500 dark:text-zinc-400">
            Recipient
          </p>
          <p className={`text-sm font-semibold ${account.is_recipient ? "text-green-600" : "text-amber-600"}`}>
            {account.is_recipient ? "Enabled" : "Not Configured"}
          </p>
        </div>
      </div>
    </div>
  );
}
