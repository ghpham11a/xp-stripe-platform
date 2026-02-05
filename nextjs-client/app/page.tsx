"use client";

import { useState, useEffect, useCallback } from "react";
import { StripeProvider } from "@/components/StripeProvider";
import { AccountSelector } from "@/components/AccountSelector";
import { CreateAccountForm } from "@/components/CreateAccountForm";
import { AccountCard } from "@/components/AccountCard";
import { PaymentMethodForm } from "@/components/PaymentMethodForm";
import { PaymentMethodList } from "@/components/PaymentMethodList";
import { BankAccountForm } from "@/components/BankAccountForm";
import { ExternalAccountList } from "@/components/ExternalAccountList";
import { PayUserForm } from "@/components/PayUserForm";
import {
  listAccounts,
  getAccount,
  deleteAccount,
  listPaymentMethods,
  listExternalAccounts,
  upgradeToMerchant,
  createOnboardingLink,
} from "@/lib/api";
import type { Account, PaymentMethod, ExternalAccount } from "@/lib/types";

function StripeDemoContent() {
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [selectedAccountId, setSelectedAccountId] = useState<string | null>(null);
  const [selectedAccount, setSelectedAccount] = useState<Account | null>(null);
  const [paymentMethods, setPaymentMethods] = useState<PaymentMethod[]>([]);
  const [externalAccounts, setExternalAccounts] = useState<ExternalAccount[]>([]);

  const [loadingAccounts, setLoadingAccounts] = useState(true);
  const [loadingAccount, setLoadingAccount] = useState(false);
  const [loadingPaymentMethods, setLoadingPaymentMethods] = useState(false);
  const [loadingExternalAccounts, setLoadingExternalAccounts] = useState(false);
  const [deletingAccount, setDeletingAccount] = useState(false);

  const [showCreateForm, setShowCreateForm] = useState(false);
  const [showPaymentMethodForm, setShowPaymentMethodForm] = useState(false);
  const [showBankAccountForm, setShowBankAccountForm] = useState(false);
  const [showPayUserForm, setShowPayUserForm] = useState(false);
  const [upgradingToMerchant, setUpgradingToMerchant] = useState(false);
  const [, setIsMerchant] = useState(false);
  const [isRecipient, setIsRecipient] = useState(false);
  const [onboardingUrl, setOnboardingUrl] = useState<string | null>(null);
  const [loadingOnboardingLink, setLoadingOnboardingLink] = useState(false);

  // Fetch accounts list
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

  // Fetch selected account details
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

  // Fetch payment methods for selected account
  const fetchPaymentMethods = useCallback(async (accountId: string) => {
    setLoadingPaymentMethods(true);
    try {
      const data = await listPaymentMethods(accountId);
      setPaymentMethods(data);
    } catch (err) {
      console.error("Failed to fetch payment methods:", err);
      setPaymentMethods([]);
    } finally {
      setLoadingPaymentMethods(false);
    }
  }, []);

  // Fetch external accounts for selected account
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

  // Fetch onboarding link for selected account
  const fetchOnboardingLink = useCallback(async (accountId: string) => {
    setLoadingOnboardingLink(true);
    setOnboardingUrl(null);
    try {
      // Include account ID in URL so we can restore state after redirect
      const baseUrl = window.location.origin + window.location.pathname;
      const returnUrl = `${baseUrl}?account=${accountId}`;
      const refreshUrl = `${baseUrl}?account=${accountId}&refresh=true`;
      const result = await createOnboardingLink(
        accountId,
        returnUrl,
        refreshUrl
      );
      if (result.url) {
        setOnboardingUrl(result.url);
      }
    } catch (err) {
      // No onboarding needed or error - that's fine, just don't show the button
      console.log("No onboarding link available:", err);
      setOnboardingUrl(null);
    } finally {
      setLoadingOnboardingLink(false);
    }
  }, []);

  // Load accounts on mount and check for account ID in URL (from onboarding redirect)
  useEffect(() => {
    fetchAccounts();

    // Check if we're returning from onboarding with an account ID
    const params = new URLSearchParams(window.location.search);
    const accountFromUrl = params.get("account");
    if (accountFromUrl) {
      setSelectedAccountId(accountFromUrl);
      // Clean up URL without triggering a reload
      window.history.replaceState({}, "", window.location.pathname);
    }
  }, [fetchAccounts]);

  // Load account details when selection changes
  useEffect(() => {
    if (selectedAccountId && selectedAccountId !== "new") {
      fetchAccountDetails(selectedAccountId);
      fetchPaymentMethods(selectedAccountId);
      fetchExternalAccounts(selectedAccountId);
      fetchOnboardingLink(selectedAccountId);
    } else {
      setSelectedAccount(null);
      setPaymentMethods([]);
      setExternalAccounts([]);
      setOnboardingUrl(null);
    }
  }, [selectedAccountId, fetchAccountDetails, fetchPaymentMethods, fetchExternalAccounts, fetchOnboardingLink]);

  // Handle account selection
  const handleAccountSelect = (accountId: string | null) => {
    if (accountId === "new") {
      setShowCreateForm(true);
      setSelectedAccountId(null);
    } else {
      setShowCreateForm(false);
      setSelectedAccountId(accountId);
      setIsMerchant(false); // Reset merchant state when switching accounts
      setIsRecipient(false); // Reset recipient state when switching accounts
      setShowPayUserForm(false);
      setOnboardingUrl(null);
    }
  };

  // Handle account creation
  const handleAccountCreated = (account: Account) => {
    setAccounts((prev) => [account, ...prev]);
    setSelectedAccountId(account.id);
    setShowCreateForm(false);
  };

  // Handle account deletion
  const handleDeleteAccount = async () => {
    if (!selectedAccountId) return;

    setDeletingAccount(true);
    try {
      await deleteAccount(selectedAccountId);
      setAccounts((prev) => prev.filter((a) => a.id !== selectedAccountId));
      setSelectedAccountId(null);
      setSelectedAccount(null);
    } catch (err) {
      console.error("Failed to delete account:", err);
    } finally {
      setDeletingAccount(false);
    }
  };

  // Handle payment method added
  const handlePaymentMethodAdded = () => {
    setShowPaymentMethodForm(false);
    if (selectedAccountId) {
      fetchPaymentMethods(selectedAccountId);
    }
  };

  // Handle bank account added
  const handleBankAccountAdded = () => {
    setShowBankAccountForm(false);
    if (selectedAccountId) {
      fetchExternalAccounts(selectedAccountId);
      fetchAccountDetails(selectedAccountId); // Refresh account to get updated external accounts
    }
  };

  // Handle pay user success
  const handlePayUserSuccess = () => {
    setShowPayUserForm(false);
    if (selectedAccountId) {
      fetchPaymentMethods(selectedAccountId); // Refresh in case card was saved
    }
    alert("Payment sent successfully!");
  };

  // Handle upgrade to merchant
  const handleUpgradeToMerchant = async () => {
    if (!selectedAccountId) return;

    setUpgradingToMerchant(true);
    try {
      const result = await upgradeToMerchant(selectedAccountId);
      setIsMerchant(result.is_merchant);
      setIsRecipient(result.is_recipient);
      // Refresh onboarding link in case there are additional requirements
      fetchOnboardingLink(selectedAccountId);
      fetchAccountDetails(selectedAccountId);
    } catch (err) {
      console.error("Failed to upgrade to merchant:", err);
      alert("Failed to upgrade to merchant. Check console for details.");
    } finally {
      setUpgradingToMerchant(false);
    }
  };

  // Handle start onboarding - redirect to pre-fetched URL
  const handleStartOnboarding = () => {
    if (onboardingUrl) {
      window.location.href = onboardingUrl;
    }
  };

  // Get recipient accounts for pay user dropdown (exclude current account)
  const recipientAccounts = accounts.filter(
    (a) => a.id !== selectedAccountId && a.is_recipient
  );

  return (
    <div className="min-h-screen bg-zinc-50 dark:bg-zinc-900">
      {/* Header */}
      <header className="border-b border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-950">
        <div className="mx-auto max-w-4xl px-6 py-4">
          <h1 className="text-xl font-bold text-zinc-900 dark:text-zinc-100">
            Stripe Connect Demo
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

        {/* Selected Account Dashboard */}
        {selectedAccount && !showCreateForm && (
          <div className="space-y-8">
            {/* Customer Info Section */}
            <section className="rounded-lg border border-zinc-200 bg-white p-6 shadow-sm dark:border-zinc-700 dark:bg-zinc-800">
              <div className="mb-4 flex items-center justify-between">
                <div>
                  <h3 className="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
                    Customer Info
                  </h3>
                  <p className="text-sm text-zinc-500 dark:text-zinc-400">
                    Your account details and actions
                  </p>
                </div>
                <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${
                  isRecipient || selectedAccount.is_recipient
                    ? "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
                    : "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
                }`}>
                  {isRecipient || selectedAccount.is_recipient ? "Customer + Recipient" : "Customer"}
                </span>
              </div>

              <div className="grid gap-4 sm:grid-cols-2">
                <div>
                  <p className="text-sm font-medium text-zinc-500 dark:text-zinc-400">Email</p>
                  <p className="text-sm text-zinc-900 dark:text-zinc-100">
                    {selectedAccount.email || "Not set"}
                  </p>
                </div>
                <div>
                  <p className="text-sm font-medium text-zinc-500 dark:text-zinc-400">Display Name</p>
                  <p className="text-sm text-zinc-900 dark:text-zinc-100">
                    {selectedAccount.display_name || "Not set"}
                  </p>
                </div>
                <div>
                  <p className="text-sm font-medium text-zinc-500 dark:text-zinc-400">Platform ID</p>
                  <p className="font-mono text-sm text-zinc-900 dark:text-zinc-100">
                    {selectedAccount.id}
                  </p>
                </div>
                <div>
                  <p className="text-sm font-medium text-zinc-500 dark:text-zinc-400">Stripe Account ID</p>
                  <p className="font-mono text-sm text-zinc-900 dark:text-zinc-100">
                    {selectedAccount.stripe_account_id}
                  </p>
                </div>
                <div>
                  <p className="text-sm font-medium text-zinc-500 dark:text-zinc-400">Stripe Customer ID</p>
                  <p className="font-mono text-sm text-zinc-900 dark:text-zinc-100">
                    {selectedAccount.stripe_customer_id || "Not created yet"}
                  </p>
                </div>
                <div>
                  <p className="text-sm font-medium text-zinc-500 dark:text-zinc-400">Created</p>
                  <p className="text-sm text-zinc-900 dark:text-zinc-100">
                    {new Date(selectedAccount.created).toLocaleDateString()}
                  </p>
                </div>
              </div>

              {/* Pay User Section */}
              <div className="mt-6 border-t border-zinc-200 pt-6 dark:border-zinc-700">
                <div className="mb-4 flex items-center justify-between">
                  <h4 className="text-md font-semibold text-zinc-900 dark:text-zinc-100">
                    Pay User
                  </h4>
                  {!showPayUserForm && (
                    <button
                      onClick={() => setShowPayUserForm(true)}
                      className="rounded-lg bg-purple-600 px-4 py-2 text-sm font-medium text-white hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-offset-2"
                    >
                      Pay User
                    </button>
                  )}
                </div>

                {!showPayUserForm && (
                  <p className="text-sm text-zinc-500 dark:text-zinc-400">
                    Send money to other users. You can use a saved card or enter a new one.
                  </p>
                )}

                {showPayUserForm && (
                  <PayUserForm
                    accountId={selectedAccountId!}
                    paymentMethods={paymentMethods}
                    recipientAccounts={recipientAccounts}
                    onSuccess={handlePayUserSuccess}
                    onCancel={() => setShowPayUserForm(false)}
                  />
                )}
              </div>

              {/* Onboarding Section - shows for non-recipients OR recipients with incomplete onboarding */}
              {(!selectedAccount.is_recipient || selectedAccount.is_onboarding) && (
                <div className="mt-6 border-t border-zinc-200 pt-6 dark:border-zinc-700">
                  <div className="mb-4">
                    <h4 className="text-md font-semibold text-zinc-900 dark:text-zinc-100">
                      {selectedAccount.is_recipient ? "Complete Onboarding" : "Become a Recipient"}
                    </h4>
                    <p className="text-sm text-zinc-500 dark:text-zinc-400">
                      {selectedAccount.is_recipient
                        ? "Complete your account setup to unlock all features"
                        : "Upgrade your account to receive transfers from the platform"}
                    </p>
                  </div>
                  <div className="flex gap-3">
                    {loadingOnboardingLink ? (
                      <div className="flex items-center gap-2 text-sm text-zinc-500">
                        <div className="h-4 w-4 animate-spin rounded-full border-2 border-green-600 border-t-transparent" />
                        Checking onboarding status...
                      </div>
                    ) : (
                      <>
                        {/* Show onboarding link for recipients who need to complete onboarding */}
                        {selectedAccount.is_recipient && selectedAccount.is_onboarding && onboardingUrl && (
                          <button
                            onClick={handleStartOnboarding}
                            className="rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2"
                          >
                            Continue Onboarding
                          </button>
                        )}
                        {/* Show upgrade button for non-recipients */}
                        {!selectedAccount.is_recipient && (
                          <button
                            onClick={handleUpgradeToMerchant}
                            disabled={upgradingToMerchant}
                            className="rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                          >
                            {upgradingToMerchant ? "Upgrading..." : "Become a Recipient"}
                          </button>
                        )}
                      </>
                    )}
                  </div>
                </div>
              )}
            </section>

            {/* Account Card */}
            <AccountCard
              account={selectedAccount}
              onDelete={handleDeleteAccount}
              deleting={deletingAccount}
            />

            {/* Payment Methods Section */}
            <section className="rounded-lg border border-zinc-200 bg-white p-6 shadow-sm dark:border-zinc-700 dark:bg-zinc-800">
              <div className="mb-4 flex items-center justify-between">
                <h3 className="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
                  Payment Methods
                </h3>
                {!showPaymentMethodForm && (
                  <button
                    onClick={() => setShowPaymentMethodForm(true)}
                    className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
                  >
                    Add Card
                  </button>
                )}
              </div>

              {showPaymentMethodForm ? (
                <PaymentMethodForm
                  accountId={selectedAccountId!}
                  customerId={selectedAccount?.stripe_customer_id}
                  onSuccess={handlePaymentMethodAdded}
                  onCancel={() => setShowPaymentMethodForm(false)}
                />
              ) : (
                <PaymentMethodList
                  accountId={selectedAccountId!}
                  paymentMethods={paymentMethods}
                  onRefresh={() => fetchPaymentMethods(selectedAccountId!)}
                  loading={loadingPaymentMethods}
                />
              )}
            </section>

            {/* External Accounts (Bank Accounts) Section */}
            <section className="rounded-lg border border-zinc-200 bg-white p-6 shadow-sm dark:border-zinc-700 dark:bg-zinc-800">
              <div className="mb-4 flex items-center justify-between">
                <h3 className="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
                  Bank Accounts (Payouts)
                </h3>
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
                  accountId={selectedAccountId!}
                  onSuccess={handleBankAccountAdded}
                  onCancel={() => setShowBankAccountForm(false)}
                />
              ) : (
                <ExternalAccountList
                  accountId={selectedAccountId!}
                  externalAccounts={externalAccounts}
                  onRefresh={() => {
                    fetchExternalAccounts(selectedAccountId!);
                    fetchAccountDetails(selectedAccountId!);
                  }}
                  loading={loadingExternalAccounts}
                />
              )}
            </section>
          </div>
        )}

        {/* No Account Selected State */}
        {!selectedAccount && !showCreateForm && !loadingAccounts && (
          <div className="rounded-lg border border-dashed border-zinc-300 bg-white p-12 text-center dark:border-zinc-700 dark:bg-zinc-800">
            <svg
              className="mx-auto h-12 w-12 text-zinc-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={1.5}
                d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
              />
            </svg>
            <h3 className="mt-4 text-lg font-medium text-zinc-900 dark:text-zinc-100">
              No account selected
            </h3>
            <p className="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
              Select an existing account from the dropdown or create a new one to get started.
            </p>
            <button
              onClick={() => setShowCreateForm(true)}
              className="mt-4 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
            >
              Create Your First Account
            </button>
          </div>
        )}

        {/* Loading State */}
        {loadingAccount && (
          <div className="flex items-center justify-center py-12">
            <div className="h-8 w-8 animate-spin rounded-full border-2 border-blue-600 border-t-transparent" />
          </div>
        )}

        {/* Test Data Info */}
        <div className="mt-8 rounded-lg bg-blue-50 p-4 dark:bg-blue-900/20">
          <h4 className="text-sm font-medium text-blue-900 dark:text-blue-100">
            Test Data
          </h4>
          <div className="mt-2 space-y-1 text-sm text-blue-700 dark:text-blue-300">
            <p>
              <strong>Test Card:</strong> 4242 4242 4242 4242, any future date, any CVC
            </p>
            <p>
              <strong>Test Bank:</strong> Routing: 110000000, Account: 000123456789
            </p>
          </div>
        </div>
      </main>
    </div>
  );
}

export default function Home() {
  return (
    <StripeProvider>
      <StripeDemoContent />
    </StripeProvider>
  );
}
