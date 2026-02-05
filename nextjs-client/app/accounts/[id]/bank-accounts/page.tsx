"use client";

import { useState, useCallback, useEffect } from "react";
import { BankAccountForm } from "@/components/BankAccountForm";
import { ExternalAccountList } from "@/components/ExternalAccountList";
import { useAccount } from "@/contexts/AccountContext";
import { listExternalAccounts } from "@/lib/api";
import type { ExternalAccount } from "@/lib/types";

export default function BankAccountsPage() {
  const { selectedAccountId, selectedAccount, fetchAccountDetails } = useAccount();
  const [externalAccounts, setExternalAccounts] = useState<ExternalAccount[]>([]);
  const [loadingExternalAccounts, setLoadingExternalAccounts] = useState(false);
  const [showBankAccountForm, setShowBankAccountForm] = useState(false);

  const fetchExternalAccounts = useCallback(async (accountId: string) => {
    setLoadingExternalAccounts(true);
    try {
      const data = await listExternalAccounts(accountId);
      setExternalAccounts(data);
    } catch (err) {
      console.error("Failed to fetch external accounts:", err);
      setExternalAccounts([]);
    } finally {
      setLoadingExternalAccounts(false);
    }
  }, []);

  useEffect(() => {
    if (selectedAccountId) {
      fetchExternalAccounts(selectedAccountId);
    }
  }, [selectedAccountId, fetchExternalAccounts]);

  const handleBankAccountAdded = () => {
    setShowBankAccountForm(false);
    if (selectedAccountId) {
      fetchExternalAccounts(selectedAccountId);
      fetchAccountDetails(selectedAccountId);
    }
  };

  if (!selectedAccount || !selectedAccountId) return null;

  return (
    <section className="rounded-lg border border-zinc-200 bg-white p-6 shadow-sm dark:border-zinc-700 dark:bg-zinc-800">
      <div className="mb-4 flex items-center justify-between">
        <div>
          <h3 className="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
            Bank Accounts (Payouts)
          </h3>
          <p className="text-sm text-zinc-500 dark:text-zinc-400">
            Bank accounts for receiving payouts
          </p>
        </div>
        {!showBankAccountForm && (
          <button
            onClick={() => setShowBankAccountForm(true)}
            className="rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2"
          >
            Add Bank Account
          </button>
        )}
      </div>

      {showBankAccountForm ? (
        <BankAccountForm
          accountId={selectedAccountId}
          onSuccess={handleBankAccountAdded}
          onCancel={() => setShowBankAccountForm(false)}
        />
      ) : (
        <ExternalAccountList
          accountId={selectedAccountId}
          externalAccounts={externalAccounts}
          onRefresh={() => {
            fetchExternalAccounts(selectedAccountId);
            fetchAccountDetails(selectedAccountId);
          }}
          loading={loadingExternalAccounts}
        />
      )}
    </section>
  );
}
