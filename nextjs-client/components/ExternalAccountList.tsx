"use client";

import type { ExternalAccount } from "@/lib/types";
import { deleteExternalAccount, setDefaultExternalAccount } from "@/lib/api";
import { useState } from "react";

interface ExternalAccountListProps {
  accountId: string;
  externalAccounts: ExternalAccount[];
  onRefresh: () => void;
  loading: boolean;
}

export function ExternalAccountList({
  accountId,
  externalAccounts,
  onRefresh,
  loading,
}: ExternalAccountListProps) {
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [settingDefaultId, setSettingDefaultId] = useState<string | null>(null);

  const handleDelete = async (externalAccountId: string) => {
    setDeletingId(externalAccountId);
    try {
      await deleteExternalAccount(accountId, externalAccountId);
      onRefresh();
    } catch (err) {
      console.error("Failed to delete external account:", err);
    } finally {
      setDeletingId(null);
    }
  };

  const handleSetDefault = async (externalAccountId: string) => {
    setSettingDefaultId(externalAccountId);
    try {
      await setDefaultExternalAccount(accountId, externalAccountId);
      onRefresh();
    } catch (err) {
      console.error("Failed to set default:", err);
    } finally {
      setSettingDefaultId(null);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-4">
        <div className="h-5 w-5 animate-spin rounded-full border-2 border-green-600 border-t-transparent" />
      </div>
    );
  }

  if (externalAccounts.length === 0) {
    return (
      <p className="py-4 text-center text-sm text-zinc-500 dark:text-zinc-400">
        No bank accounts attached yet.
      </p>
    );
  }

  return (
    <div className="space-y-2">
      {externalAccounts.map((ea) => (
        <div
          key={ea.id}
          className="flex items-center justify-between rounded-lg border border-zinc-200 bg-zinc-50 px-4 py-3 dark:border-zinc-700 dark:bg-zinc-800"
        >
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-full bg-green-100 text-green-600 dark:bg-green-900/30 dark:text-green-400">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth={1.5}
                stroke="currentColor"
                className="h-5 w-5"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M2.25 21h19.5m-18-18v18m10.5-18v18m6-13.5V21M6.75 6.75h.75m-.75 3h.75m-.75 3h.75m3-6h.75m-.75 3h.75m-.75 3h.75M6.75 21v-3.375c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21M3 3h12m-.75 4.5H21m-3.75 3.75h.008v.008h-.008v-.008zm0 3h.008v.008h-.008v-.008zm0 3h.008v.008h-.008v-.008z"
                />
              </svg>
            </div>
            <div>
              <div className="flex items-center gap-2">
                <p className="text-sm font-medium text-zinc-900 dark:text-zinc-100">
                  {ea.bank_name || "Bank Account"} •••• {ea.last4}
                </p>
                {ea.default_for_currency && (
                  <span className="rounded bg-green-100 px-2 py-0.5 text-xs font-medium text-green-700 dark:bg-green-900/30 dark:text-green-400">
                    Default
                  </span>
                )}
              </div>
              <p className="text-xs text-zinc-500 dark:text-zinc-400">
                {ea.currency.toUpperCase()} · {ea.country}
                {ea.status && ` · ${ea.status}`}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            {!ea.default_for_currency && (
              <button
                onClick={() => handleSetDefault(ea.id)}
                disabled={settingDefaultId === ea.id}
                className="text-sm text-blue-600 hover:underline disabled:opacity-50 dark:text-blue-400"
              >
                {settingDefaultId === ea.id ? "Setting..." : "Set Default"}
              </button>
            )}
            <button
              onClick={() => handleDelete(ea.id)}
              disabled={deletingId === ea.id}
              className="text-sm text-red-600 hover:underline disabled:opacity-50 dark:text-red-400"
            >
              {deletingId === ea.id ? "Removing..." : "Remove"}
            </button>
          </div>
        </div>
      ))}
    </div>
  );
}
