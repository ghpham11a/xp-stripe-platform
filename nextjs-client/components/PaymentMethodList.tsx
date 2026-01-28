"use client";

import type { PaymentMethod } from "@/lib/types";
import { deletePaymentMethod } from "@/lib/api";
import { useState } from "react";

interface PaymentMethodListProps {
  accountId: string;
  paymentMethods: PaymentMethod[];
  onRefresh: () => void;
  loading: boolean;
}

const brandLogos: Record<string, string> = {
  visa: "Visa",
  mastercard: "Mastercard",
  amex: "Amex",
  discover: "Discover",
  diners: "Diners",
  jcb: "JCB",
  unionpay: "UnionPay",
};

export function PaymentMethodList({
  accountId,
  paymentMethods,
  onRefresh,
  loading,
}: PaymentMethodListProps) {
  const [deletingId, setDeletingId] = useState<string | null>(null);

  const handleDelete = async (paymentMethodId: string) => {
    setDeletingId(paymentMethodId);
    try {
      await deletePaymentMethod(accountId, paymentMethodId);
      onRefresh();
    } catch (err) {
      console.error("Failed to delete payment method:", err);
    } finally {
      setDeletingId(null);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-4">
        <div className="h-5 w-5 animate-spin rounded-full border-2 border-blue-600 border-t-transparent" />
      </div>
    );
  }

  if (paymentMethods.length === 0) {
    return (
      <p className="py-4 text-center text-sm text-zinc-500 dark:text-zinc-400">
        No payment methods attached yet.
      </p>
    );
  }

  return (
    <div className="space-y-2">
      {paymentMethods.map((pm) => (
        <div
          key={pm.id}
          className="flex items-center justify-between rounded-lg border border-zinc-200 bg-zinc-50 px-4 py-3 dark:border-zinc-700 dark:bg-zinc-800"
        >
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-14 items-center justify-center rounded bg-white text-xs font-bold text-zinc-600 shadow-sm dark:bg-zinc-700 dark:text-zinc-300">
              {pm.card ? brandLogos[pm.card.brand] || pm.card.brand.toUpperCase() : pm.type}
            </div>
            <div>
              {pm.card && (
                <>
                  <p className="text-sm font-medium text-zinc-900 dark:text-zinc-100">
                    •••• {pm.card.last4}
                  </p>
                  <p className="text-xs text-zinc-500 dark:text-zinc-400">
                    Expires {pm.card.exp_month.toString().padStart(2, "0")}/{pm.card.exp_year}
                  </p>
                </>
              )}
            </div>
          </div>
          <button
            onClick={() => handleDelete(pm.id)}
            disabled={deletingId === pm.id}
            className="text-sm text-red-600 hover:underline disabled:opacity-50 dark:text-red-400"
          >
            {deletingId === pm.id ? "Removing..." : "Remove"}
          </button>
        </div>
      ))}
    </div>
  );
}
