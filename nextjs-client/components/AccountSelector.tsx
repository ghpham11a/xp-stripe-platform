"use client";

import type { Account } from "@/lib/types";

interface AccountSelectorProps {
  accounts: Account[];
  selectedAccountId: string | null;
  onSelect: (accountId: string | null) => void;
  loading: boolean;
}

export function AccountSelector({
  accounts,
  selectedAccountId,
  onSelect,
  loading,
}: AccountSelectorProps) {
  return (
    <div className="flex items-center gap-4">
      <label htmlFor="account-select" className="text-sm font-medium text-zinc-700 dark:text-zinc-300">
        Account:
      </label>
      <select
        id="account-select"
        value={selectedAccountId || ""}
        onChange={(e) => onSelect(e.target.value || null)}
        disabled={loading}
        className="flex-1 rounded-lg border border-zinc-300 bg-white px-4 py-2 text-sm text-zinc-900 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500 disabled:opacity-50 dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
      >
        <option value="">-- Select an account --</option>
        {accounts.map((account) => (
          <option key={account.id} value={account.id}>
            {account.display_name || account.email || account.id}
          </option>
        ))}
        <option value="new">+ Create New Account</option>
      </select>
    </div>
  );
}
