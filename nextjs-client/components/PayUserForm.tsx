"use client";

import { useState, useEffect } from "react";
import { loadStripe } from "@stripe/stripe-js";
import {
  Elements,
  PaymentElement,
  useStripe,
  useElements,
} from "@stripe/react-stripe-js";
import { createPaymentIntent, payUser } from "@/lib/api";
import type { Account, PaymentMethod } from "@/lib/types";

const stripePromise = loadStripe(
  process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY!
);

interface PaymentFormInnerProps {
  onSuccess: () => void;
  onCancel: () => void;
  processing: boolean;
  setProcessing: (processing: boolean) => void;
}

function PaymentFormInner({
  onSuccess,
  onCancel,
  processing,
  setProcessing,
}: PaymentFormInnerProps) {
  const stripe = useStripe();
  const elements = useElements();
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!stripe || !elements) return;

    setProcessing(true);
    setError(null);

    const result = await stripe.confirmPayment({
      elements,
      confirmParams: {
        return_url: window.location.href,
      },
      redirect: "if_required",
    });

    if (result.error) {
      setError(result.error.message || "An error occurred");
      setProcessing(false);
    } else if (result.paymentIntent?.status === "succeeded") {
      onSuccess();
    } else {
      setError("Payment was not completed. Please try again.");
      setProcessing(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <PaymentElement />
      {error && (
        <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
      )}
      <div className="flex gap-3">
        <button
          type="submit"
          disabled={processing || !stripe}
          className="rounded-lg bg-purple-600 px-4 py-2 text-sm font-medium text-white hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-offset-2 disabled:opacity-50"
        >
          {processing ? "Processing..." : "Pay"}
        </button>
        <button
          type="button"
          onClick={onCancel}
          disabled={processing}
          className="rounded-lg border border-zinc-300 bg-white px-4 py-2 text-sm font-medium text-zinc-700 hover:bg-zinc-50 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-offset-2 dark:border-zinc-600 dark:bg-zinc-700 dark:text-zinc-300"
        >
          Cancel
        </button>
      </div>
    </form>
  );
}

interface PayUserFormProps {
  accountId: string;
  paymentMethods: PaymentMethod[];
  recipientAccounts: Account[];
  onSuccess: () => void;
  onCancel: () => void;
}

export function PayUserForm({
  accountId,
  paymentMethods,
  recipientAccounts,
  onSuccess,
  onCancel,
}: PayUserFormProps) {
  const [paymentMode, setPaymentMode] = useState<"saved" | "new">(
    paymentMethods.length > 0 ? "saved" : "new"
  );
  const [selectedPaymentMethod, setSelectedPaymentMethod] = useState("");
  const [selectedRecipient, setSelectedRecipient] = useState("");
  const [amount, setAmount] = useState("");
  const [saveCard, setSaveCard] = useState(false);
  const [processing, setProcessing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [clientSecret, setClientSecret] = useState<string | null>(null);
  const [loadingIntent, setLoadingIntent] = useState(false);

  // Reset client secret when switching modes or changing params
  useEffect(() => {
    setClientSecret(null);
  }, [paymentMode, selectedRecipient, amount, saveCard]);

  // Handle saved card payment
  const handleSavedCardPayment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedPaymentMethod || !selectedRecipient || !amount) return;

    setProcessing(true);
    setError(null);

    try {
      const amountInCents = Math.round(parseFloat(amount) * 100);
      await payUser(accountId, selectedRecipient, selectedPaymentMethod, amountInCents);
      onSuccess();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Payment failed");
      setProcessing(false);
    }
  };

  // Create PaymentIntent for new card payment
  const handleCreatePaymentIntent = async () => {
    if (!selectedRecipient || !amount) {
      setError("Please select a recipient and enter an amount");
      return;
    }

    setLoadingIntent(true);
    setError(null);

    try {
      const amountInCents = Math.round(parseFloat(amount) * 100);
      const result = await createPaymentIntent(
        accountId,
        selectedRecipient,
        amountInCents,
        saveCard
      );
      setClientSecret(result.client_secret);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to initialize payment");
    } finally {
      setLoadingIntent(false);
    }
  };

  const handlePaymentSuccess = () => {
    onSuccess();
  };

  return (
    <div className="space-y-4">
      {/* Payment Mode Toggle */}
      <div className="flex gap-2">
        <button
          type="button"
          onClick={() => setPaymentMode("saved")}
          disabled={paymentMethods.length === 0}
          className={`flex-1 rounded-lg px-4 py-2 text-sm font-medium transition-colors ${
            paymentMode === "saved"
              ? "bg-purple-600 text-white"
              : "bg-zinc-100 text-zinc-700 hover:bg-zinc-200 dark:bg-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-600"
          } disabled:cursor-not-allowed disabled:opacity-50`}
        >
          Use Saved Card
        </button>
        <button
          type="button"
          onClick={() => setPaymentMode("new")}
          className={`flex-1 rounded-lg px-4 py-2 text-sm font-medium transition-colors ${
            paymentMode === "new"
              ? "bg-purple-600 text-white"
              : "bg-zinc-100 text-zinc-700 hover:bg-zinc-200 dark:bg-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-600"
          }`}
        >
          Use New Card
        </button>
      </div>

      {/* Recipient Selection */}
      <div>
        <label className="block text-sm font-medium text-zinc-700 dark:text-zinc-300">
          Recipient
        </label>
        <select
          value={selectedRecipient}
          onChange={(e) => setSelectedRecipient(e.target.value)}
          className="mt-1 block w-full rounded-md border border-zinc-300 bg-white px-3 py-2 text-sm shadow-sm focus:border-purple-500 focus:outline-none focus:ring-1 focus:ring-purple-500 dark:border-zinc-600 dark:bg-zinc-700 dark:text-white"
          required
        >
          <option value="">Select a recipient...</option>
          {recipientAccounts.map((account) => (
            <option key={account.id} value={account.id}>
              {account.display_name || account.email || account.id}
            </option>
          ))}
        </select>
        {recipientAccounts.length === 0 && (
          <p className="mt-1 text-sm text-zinc-500">
            No recipient accounts available. Another user must become a recipient first.
          </p>
        )}
      </div>

      {/* Amount Input */}
      <div>
        <label className="block text-sm font-medium text-zinc-700 dark:text-zinc-300">
          Amount (USD)
        </label>
        <div className="relative mt-1">
          <span className="absolute left-3 top-2 text-zinc-500">$</span>
          <input
            type="number"
            step="0.01"
            min="0.50"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="10.00"
            className="block w-full rounded-md border border-zinc-300 bg-white py-2 pl-7 pr-3 text-sm shadow-sm focus:border-purple-500 focus:outline-none focus:ring-1 focus:ring-purple-500 dark:border-zinc-600 dark:bg-zinc-700 dark:text-white"
            required
          />
        </div>
      </div>

      {error && (
        <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
      )}

      {/* Saved Card Payment Form */}
      {paymentMode === "saved" && (
        <form onSubmit={handleSavedCardPayment} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-zinc-700 dark:text-zinc-300">
              Payment Method
            </label>
            <select
              value={selectedPaymentMethod}
              onChange={(e) => setSelectedPaymentMethod(e.target.value)}
              className="mt-1 block w-full rounded-md border border-zinc-300 bg-white px-3 py-2 text-sm shadow-sm focus:border-purple-500 focus:outline-none focus:ring-1 focus:ring-purple-500 dark:border-zinc-600 dark:bg-zinc-700 dark:text-white"
              required
            >
              <option value="">Select a payment method...</option>
              {paymentMethods.map((pm) => (
                <option key={pm.id} value={pm.id}>
                  {pm.card
                    ? `${pm.card.brand.toUpperCase()} ending in ${pm.card.last4}`
                    : pm.id}
                </option>
              ))}
            </select>
          </div>

          <div className="flex gap-3">
            <button
              type="submit"
              disabled={
                processing ||
                !selectedRecipient ||
                !amount ||
                !selectedPaymentMethod
              }
              className="rounded-lg bg-purple-600 px-4 py-2 text-sm font-medium text-white hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
            >
              {processing ? "Processing..." : "Pay"}
            </button>
            <button
              type="button"
              onClick={onCancel}
              disabled={processing}
              className="rounded-lg border border-zinc-300 bg-white px-4 py-2 text-sm font-medium text-zinc-700 hover:bg-zinc-50 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-offset-2 dark:border-zinc-600 dark:bg-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-600"
            >
              Cancel
            </button>
          </div>
        </form>
      )}

      {/* New Card Payment Form */}
      {paymentMode === "new" && !clientSecret && (
        <div className="space-y-4">
          {/* Save Card Checkbox */}
          <label className="flex items-center gap-2">
            <input
              type="checkbox"
              checked={saveCard}
              onChange={(e) => setSaveCard(e.target.checked)}
              className="h-4 w-4 rounded border-zinc-300 text-purple-600 focus:ring-purple-500"
            />
            <span className="text-sm text-zinc-700 dark:text-zinc-300">
              Save this card for future payments
            </span>
          </label>

          <div className="flex gap-3">
            <button
              type="button"
              onClick={handleCreatePaymentIntent}
              disabled={loadingIntent || !selectedRecipient || !amount}
              className="rounded-lg bg-purple-600 px-4 py-2 text-sm font-medium text-white hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
            >
              {loadingIntent ? "Loading..." : "Continue to Card Entry"}
            </button>
            <button
              type="button"
              onClick={onCancel}
              disabled={loadingIntent}
              className="rounded-lg border border-zinc-300 bg-white px-4 py-2 text-sm font-medium text-zinc-700 hover:bg-zinc-50 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-offset-2 dark:border-zinc-600 dark:bg-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-600"
            >
              Cancel
            </button>
          </div>
        </div>
      )}

      {/* Stripe Elements for new card */}
      {paymentMode === "new" && clientSecret && (
        <Elements
          stripe={stripePromise}
          options={{
            clientSecret,
            appearance: {
              theme: "stripe",
              variables: {
                colorPrimary: "#9333ea",
              },
            },
          }}
        >
          <div className="space-y-4">
            <div className="rounded-lg bg-purple-50 p-3 dark:bg-purple-900/20">
              <p className="text-sm text-purple-700 dark:text-purple-300">
                Paying ${parseFloat(amount).toFixed(2)} to{" "}
                {recipientAccounts.find((a) => a.id === selectedRecipient)
                  ?.display_name ||
                  recipientAccounts.find((a) => a.id === selectedRecipient)
                    ?.email ||
                  "recipient"}
                {saveCard && " (card will be saved)"}
              </p>
            </div>
            <PaymentFormInner
              onSuccess={handlePaymentSuccess}
              onCancel={onCancel}
              processing={processing}
              setProcessing={setProcessing}
            />
          </div>
        </Elements>
      )}
    </div>
  );
}
