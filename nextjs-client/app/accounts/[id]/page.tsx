"use client";

import { useState, useCallback, useEffect } from "react";
import { useRouter } from "next/navigation";
import { AccountCard } from "@/components/AccountCard";
import { PayUserForm } from "@/components/PayUserForm";
import { useAccount } from "@/contexts/AccountContext";
import { useToast } from "@/contexts/ToastContext";
import {
  upgradeToMerchant,
  createOnboardingLink,
  listPaymentMethods,
} from "@/lib/api";
import type { PaymentMethod } from "@/lib/types";
import { TestCardInfo } from "@/components/TestCardInfo";

export default function AccountDetailsPage() {
  const router = useRouter();
  const { showToast } = useToast();
  const {
    accounts,
    selectedAccountId,
    selectedAccount,
    fetchAccountDetails,
    deleteAccount,
    deletingAccount,
  } = useAccount();

  const [paymentMethods, setPaymentMethods] = useState<PaymentMethod[]>([]);
  const [showPayUserForm, setShowPayUserForm] = useState(false);
  const [upgradingToMerchant, setUpgradingToMerchant] = useState(false);
  const [onboardingUrl, setOnboardingUrl] = useState<string | null>(null);
  const [loadingOnboardingLink, setLoadingOnboardingLink] = useState(false);

  // Fetch payment methods for the PayUserForm
  const fetchPaymentMethods = useCallback(async (accountId: string) => {
    try {
      const data = await listPaymentMethods(accountId);
      setPaymentMethods(data);
    } catch (err) {
      console.error("Failed to fetch payment methods:", err);
      setPaymentMethods([]);
    }
  }, []);

  // Fetch onboarding link
  const fetchOnboardingLink = useCallback(async (accountId: string) => {
    setLoadingOnboardingLink(true);
    setOnboardingUrl(null);
    try {
      const baseUrl = window.location.origin;
      const returnUrl = `${baseUrl}/accounts/${accountId}`;
      const refreshUrl = `${baseUrl}/accounts/${accountId}?refresh=true`;
      const result = await createOnboardingLink(accountId, returnUrl, refreshUrl);
      if (result.url) {
        setOnboardingUrl(result.url);
      }
    } catch (err) {
      console.log("No onboarding link available:", err);
      setOnboardingUrl(null);
    } finally {
      setLoadingOnboardingLink(false);
    }
  }, []);

  // Fetch data when account changes
  useEffect(() => {
    if (selectedAccountId) {
      fetchPaymentMethods(selectedAccountId);
      fetchOnboardingLink(selectedAccountId);
    }
  }, [selectedAccountId, fetchPaymentMethods, fetchOnboardingLink]);

  const handleDeleteAccount = async () => {
    if (!selectedAccountId) return;
    try {
      await deleteAccount(selectedAccountId);
      showToast("Account deleted successfully", "success");
      router.push("/");
    } catch (err) {
      console.error("Failed to delete account:", err);
      showToast(
        err instanceof Error ? err.message : "Failed to delete account",
        "error"
      );
    }
  };

  const handleUpgradeToMerchant = async () => {
    if (!selectedAccountId) return;
    setUpgradingToMerchant(true);
    try {
      await upgradeToMerchant(selectedAccountId);
      fetchOnboardingLink(selectedAccountId);
      fetchAccountDetails(selectedAccountId);
      showToast("Account upgraded to recipient successfully", "success");
    } catch (err) {
      console.error("Failed to upgrade to merchant:", err);
      showToast(
        err instanceof Error ? err.message : "Failed to upgrade to recipient",
        "error"
      );
    } finally {
      setUpgradingToMerchant(false);
    }
  };

  const handleStartOnboarding = () => {
    if (onboardingUrl) {
      window.location.href = onboardingUrl;
    }
  };

  const handlePayUserSuccess = () => {
    setShowPayUserForm(false);
    if (selectedAccountId) {
      fetchPaymentMethods(selectedAccountId);
    }
    showToast("Payment sent successfully!", "success");
  };

  const recipientAccounts = accounts.filter(
    (a) => a.id !== selectedAccountId && a.is_recipient
  );

  if (!selectedAccount) return null;

  return (
    <div className="space-y-6">
      {/* Customer Info Section */}
      <section className="rounded-lg border border-zinc-200 bg-white p-6 shadow-sm dark:border-zinc-700 dark:bg-zinc-800">
        <div className="mb-4">
          <h3 className="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
            Customer Info
          </h3>
          <p className="text-sm text-zinc-500 dark:text-zinc-400">
            Your account details and actions
          </p>
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

        {/* Onboarding Section */}
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
                  {selectedAccount.is_recipient && selectedAccount.is_onboarding && onboardingUrl && (
                    <button
                      onClick={handleStartOnboarding}
                      className="rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2"
                    >
                      Continue Onboarding
                    </button>
                  )}
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

      {/* Account Card with Delete */}
      <AccountCard
        account={selectedAccount}
        onDelete={handleDeleteAccount}
        deleting={deletingAccount}
      />

      <TestCardInfo/>

    </div>
  );
}
