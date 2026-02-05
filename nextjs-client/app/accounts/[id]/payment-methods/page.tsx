"use client";

import { useState, useCallback, useEffect } from "react";
import { PaymentMethodForm } from "@/components/PaymentMethodForm";
import { PaymentMethodList } from "@/components/PaymentMethodList";
import { useAccount } from "@/contexts/AccountContext";
import { listPaymentMethods } from "@/lib/api";
import type { PaymentMethod } from "@/lib/types";
import { TestCardInfo } from "@/components/TestCardInfo";

export default function PaymentMethodsPage() {
  const { selectedAccountId, selectedAccount } = useAccount();
  const [paymentMethods, setPaymentMethods] = useState<PaymentMethod[]>([]);
  const [loadingPaymentMethods, setLoadingPaymentMethods] = useState(false);
  const [showPaymentMethodForm, setShowPaymentMethodForm] = useState(false);

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

  useEffect(() => {
    if (selectedAccountId) {
      fetchPaymentMethods(selectedAccountId);
    }
  }, [selectedAccountId, fetchPaymentMethods]);

  const handlePaymentMethodAdded = () => {
    setShowPaymentMethodForm(false);
    if (selectedAccountId) {
      fetchPaymentMethods(selectedAccountId);
    }
  };

  if (!selectedAccount || !selectedAccountId) return null;

  return (
    <>
      <section className="rounded-lg border border-zinc-200 bg-white p-6 shadow-sm dark:border-zinc-700 dark:bg-zinc-800">
        <div className="mb-4 flex items-center justify-between">
          <div>
            <h3 className="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
              Payment Methods
            </h3>
            <p className="text-sm text-zinc-500 dark:text-zinc-400">
              Saved cards for making payments
            </p>
          </div>
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
            accountId={selectedAccountId}
            customerId={selectedAccount.stripe_customer_id}
            onSuccess={handlePaymentMethodAdded}
            onCancel={() => setShowPaymentMethodForm(false)}
          />
        ) : (
          <PaymentMethodList
            accountId={selectedAccountId}
            paymentMethods={paymentMethods}
            onRefresh={() => fetchPaymentMethods(selectedAccountId)}
            loading={loadingPaymentMethods}
          />
        )}
      </section>

      <TestCardInfo/>

    </>
  );
}
