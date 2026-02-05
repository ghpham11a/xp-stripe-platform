"use client";

import { useState } from "react";
import Link from "next/link";
import { AccountSelector } from "@/components/AccountSelector";
import { CreateAccountForm } from "@/components/CreateAccountForm";
import { useAccount } from "@/contexts/AccountContext";
import type { Account } from "@/lib/types";

export default function Home() {
  const { accounts, selectedAccountId, selectedAccount, loadingAccounts, addAccount, setSelectedAccountId } = useAccount();
  const [showCreateForm, setShowCreateForm] = useState(false);

  const handleAccountSelect = (accountId: string | null) => {
    if (accountId === "new") {
      setShowCreateForm(true);
      setSelectedAccountId(null);
    } else {
      setShowCreateForm(false);
      setSelectedAccountId(accountId);
    }
  };

  const handleAccountCreated = (account: Account) => {
    addAccount(account);
    setSelectedAccountId(account.id);
    setShowCreateForm(false);
  };

  const navigationCards = [
    {
      title: "Account Details",
      description: "View and manage your account information, pay users, and upgrade to recipient",
      href: `/accounts/${selectedAccountId}`,
      icon: (
        <svg className="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
        </svg>
      ),
      color: "blue",
    },
    {
      title: "Payment Methods",
      description: "Manage saved cards for making payments to other users",
      href: `/accounts/${selectedAccountId}/payment-methods`,
      icon: (
        <svg className="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
        </svg>
      ),
      color: "purple",
    },
    {
      title: "Bank Accounts",
      description: "Manage bank accounts for receiving payouts",
      href: `/accounts/${selectedAccountId}/bank-accounts`,
      icon: (
        <svg className="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M8 14v3m4-3v3m4-3v3M3 21h18M3 10h18M3 7l9-4 9 4M4 10h16v11H4V10z" />
        </svg>
      ),
      color: "green",
    },
  ];

  const colorClasses = {
    blue: "bg-blue-50 text-blue-600 group-hover:bg-blue-100 dark:bg-blue-900/20 dark:text-blue-400 dark:group-hover:bg-blue-900/30",
    purple: "bg-purple-50 text-purple-600 group-hover:bg-purple-100 dark:bg-purple-900/20 dark:text-purple-400 dark:group-hover:bg-purple-900/30",
    green: "bg-green-50 text-green-600 group-hover:bg-green-100 dark:bg-green-900/20 dark:text-green-400 dark:group-hover:bg-green-900/30",
  };

  return (
    <div className="min-h-screen bg-zinc-50 dark:bg-zinc-900">
      {/* Header */}
      <header className="border-b border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-950">
        <div className="mx-auto max-w-4xl px-6 py-4">
          <h1 className="text-xl font-bold text-zinc-900 dark:text-zinc-100">
            Stripe Demo
          </h1>
          <p className="text-sm text-zinc-500 dark:text-zinc-400">
            Customer accounts with the ability to pay other users and become recipients
          </p>
        </div>
      </header>

      {/* Main Content */}
      <main className="mx-auto max-w-4xl px-6 py-8">
        {/* Account Selector */}
        <div className="mb-8">
          <AccountSelector
            accounts={accounts}
            selectedAccountId={selectedAccountId}
            onSelect={handleAccountSelect}
            loading={loadingAccounts}
          />
        </div>

        {/* Create Account Form */}
        {showCreateForm && (
          <div className="mb-8">
            <CreateAccountForm
              onCreated={handleAccountCreated}
              onCancel={() => setShowCreateForm(false)}
            />
          </div>
        )}

        {/* Navigation Cards - shown when account is selected */}
        {selectedAccount && !showCreateForm && (
          <div className="mb-8">
            <div className="mb-4">
              <h2 className="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
                {selectedAccount.display_name || selectedAccount.email || "Unnamed Account"}
              </h2>
              <p className="font-mono text-xs text-zinc-400 dark:text-zinc-500">
                {selectedAccount.id}
              </p>
            </div>
            <div className="grid gap-4 sm:grid-cols-3">
              {navigationCards.map((card) => (
                <Link
                  key={card.title}
                  href={card.href}
                  className="group rounded-lg border border-zinc-200 bg-white p-6 shadow-sm transition-all hover:border-zinc-300 hover:shadow-md dark:border-zinc-700 dark:bg-zinc-800 dark:hover:border-zinc-600"
                >
                  <div className={`mb-4 inline-flex rounded-lg p-3 ${colorClasses[card.color as keyof typeof colorClasses]}`}>
                    {card.icon}
                  </div>
                  <h3 className="mb-2 text-lg font-semibold text-zinc-900 dark:text-zinc-100">
                    {card.title}
                  </h3>
                  <p className="text-sm text-zinc-500 dark:text-zinc-400">
                    {card.description}
                  </p>
                </Link>
              ))}
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
