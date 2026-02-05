"use client";

import { useEffect, use } from "react";
import { useRouter, usePathname } from "next/navigation";
import Link from "next/link";
import { AccountSelector } from "@/components/AccountSelector";
import { useAccount } from "@/contexts/AccountContext";

interface AccountLayoutProps {
  children: React.ReactNode;
  params: Promise<{ id: string }>;
}

export default function AccountLayout({ children, params }: AccountLayoutProps) {
  const { id } = use(params);
  const router = useRouter();
  const pathname = usePathname();
  const {
    accounts,
    selectedAccountId,
    selectedAccount,
    loadingAccounts,
    loadingAccount,
    setSelectedAccountId
  } = useAccount();

  // Sync URL param with context
  useEffect(() => {
    if (id && id !== selectedAccountId) {
      setSelectedAccountId(id);
    }
  }, [id, selectedAccountId, setSelectedAccountId]);

  const handleAccountSelect = (accountId: string | null) => {
    if (accountId === "new") {
      router.push("/");
    } else if (accountId) {
      setSelectedAccountId(accountId);
      // Navigate to same sub-page for new account
      const currentPath = pathname.split("/").slice(3).join("/");
      router.push(`/accounts/${accountId}${currentPath ? `/${currentPath}` : ""}`);
    } else {
      router.push("/");
    }
  };

  const tabs = [
    { name: "Account Details", href: `/accounts/${id}`, exact: true },
    { name: "Payment Methods", href: `/accounts/${id}/payment-methods`, exact: false },
    { name: "Bank Accounts", href: `/accounts/${id}/bank-accounts`, exact: false },
  ];

  const isActiveTab = (tab: { href: string; exact: boolean }) => {
    if (tab.exact) {
      return pathname === tab.href;
    }
    return pathname.startsWith(tab.href);
  };

  return (
    <div className="min-h-screen bg-zinc-50 dark:bg-zinc-900">
      {/* Header */}
      <header className="border-b border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-950">
        <div className="mx-auto max-w-4xl px-6 py-4">
          <div className="flex items-center justify-between">
            <div>
              <div className="flex items-center gap-3">
                <Link
                  href="/"
                  className="flex items-center gap-1 text-sm text-zinc-500 hover:text-zinc-700 dark:text-zinc-400 dark:hover:text-zinc-200"
                >
                  <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                  </svg>
                  Back
                </Link>
                <span className="text-zinc-300 dark:text-zinc-600">|</span>
                <h1 className="text-xl font-bold text-zinc-900 dark:text-zinc-100">
                  Stripe Connect Demo
                </h1>
              </div>
              <p className="text-sm text-zinc-500 dark:text-zinc-400">
                Customer accounts with the ability to pay other users and become recipients
              </p>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="mx-auto max-w-4xl px-6 py-8">

        {/* Account Name and Navigation Tabs */}
        {selectedAccount && (
          <div className="mb-6">
            <div className="mb-4 flex items-center justify-between">
              <div>
                <h2 className="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
                  {selectedAccount.display_name || selectedAccount.email || "Unnamed Account"}
                </h2>
                <p className="font-mono text-xs text-zinc-400 dark:text-zinc-500">
                  {selectedAccount.id}
                </p>
              </div>
              <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${
                selectedAccount.is_recipient
                  ? "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
                  : "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
              }`}>
                {selectedAccount.is_recipient ? "Customer + Recipient" : "Customer"}
              </span>
            </div>
          </div>
        )}

        {/* Loading State */}
        {loadingAccount && !selectedAccount && (
          <div className="flex items-center justify-center py-12">
            <div className="h-8 w-8 animate-spin rounded-full border-2 border-blue-600 border-t-transparent" />
          </div>
        )}

        {/* Page Content */}
        {selectedAccount && children}
      </main>
    </div>
  );
}
