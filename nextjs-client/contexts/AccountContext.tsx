"use client";

import { createContext, useContext, useState, useEffect, useCallback, ReactNode } from "react";
import { listAccounts, getAccount, deleteAccount as deleteAccountApi } from "@/lib/api";
import type { Account } from "@/lib/types";

interface AccountContextType {
  accounts: Account[];
  selectedAccountId: string | null;
  selectedAccount: Account | null;
  loadingAccounts: boolean;
  loadingAccount: boolean;
  setSelectedAccountId: (id: string | null) => void;
  fetchAccounts: () => Promise<void>;
  fetchAccountDetails: (accountId: string) => Promise<void>;
  addAccount: (account: Account) => void;
  deleteAccount: (accountId: string) => Promise<void>;
  deletingAccount: boolean;
}

const AccountContext = createContext<AccountContextType | null>(null);

export function AccountProvider({ children }: { children: ReactNode }) {
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [selectedAccountId, setSelectedAccountId] = useState<string | null>(null);
  const [selectedAccount, setSelectedAccount] = useState<Account | null>(null);
  const [loadingAccounts, setLoadingAccounts] = useState(true);
  const [loadingAccount, setLoadingAccount] = useState(false);
  const [deletingAccount, setDeletingAccount] = useState(false);

  const fetchAccounts = useCallback(async () => {
    setLoadingAccounts(true);
    try {
      const data = await listAccounts();
      setAccounts(data);
    } catch (err) {
      console.error("Failed to fetch accounts:", err);
    } finally {
      setLoadingAccounts(false);
    }
  }, []);

  const fetchAccountDetails = useCallback(async (accountId: string) => {
    setLoadingAccount(true);
    try {
      const account = await getAccount(accountId);
      setSelectedAccount(account);
    } catch (err) {
      console.error("Failed to fetch account:", err);
      setSelectedAccount(null);
    } finally {
      setLoadingAccount(false);
    }
  }, []);

  const addAccount = useCallback((account: Account) => {
    setAccounts((prev) => [account, ...prev]);
  }, []);

  const deleteAccount = useCallback(async (accountId: string) => {
    setDeletingAccount(true);
    try {
      await deleteAccountApi(accountId);
      setAccounts((prev) => prev.filter((a) => a.id !== accountId));
      if (selectedAccountId === accountId) {
        setSelectedAccountId(null);
        setSelectedAccount(null);
      }
    } catch (err) {
      console.error("Failed to delete account:", err);
      throw err;
    } finally {
      setDeletingAccount(false);
    }
  }, [selectedAccountId]);

  // Load accounts on mount
  useEffect(() => {
    fetchAccounts();
  }, [fetchAccounts]);

  // Load account details when selection changes
  useEffect(() => {
    if (selectedAccountId) {
      fetchAccountDetails(selectedAccountId);
    } else {
      setSelectedAccount(null);
    }
  }, [selectedAccountId, fetchAccountDetails]);

  return (
    <AccountContext.Provider
      value={{
        accounts,
        selectedAccountId,
        selectedAccount,
        loadingAccounts,
        loadingAccount,
        setSelectedAccountId,
        fetchAccounts,
        fetchAccountDetails,
        addAccount,
        deleteAccount,
        deletingAccount,
      }}
    >
      {children}
    </AccountContext.Provider>
  );
}

export function useAccount() {
  const context = useContext(AccountContext);
  if (!context) {
    throw new Error("useAccount must be used within an AccountProvider");
  }
  return context;
}
