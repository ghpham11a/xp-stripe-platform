"use client";

import { useState } from "react";
import { useStripe } from "@stripe/react-stripe-js";
import { createExternalAccount } from "@/lib/api";

interface BankAccountFormProps {
  accountId: string;
  onSuccess: () => void;
  onCancel: () => void;
}

export function BankAccountForm({
  accountId,
  onSuccess,
  onCancel,
}: BankAccountFormProps) {
  const stripe = useStripe();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    account_holder_name: "",
    routing_number: "",
    account_number: "",
    confirm_account_number: "",
  });

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData((prev) => ({
      ...prev,
      [e.target.name]: e.target.value,
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!stripe) {
      setError("Stripe is not initialized");
      return;
    }

    if (formData.account_number !== formData.confirm_account_number) {
      setError("Account numbers do not match");
      return;
    }

    setLoading(true);
    setError(null);

    try {
      // Create bank account token using Stripe.js
      const result = await stripe.createToken("bank_account", {
        country: "US",
        currency: "usd",
        account_holder_name: formData.account_holder_name,
        account_holder_type: "individual",
        routing_number: formData.routing_number,
        account_number: formData.account_number,
      });

      if (result.error) {
        setError(result.error.message || "Failed to create token");
        setLoading(false);
        return;
      }

      // Send token to backend to create external account
      await createExternalAccount(accountId, result.token!.id);
      onSuccess();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to add bank account");
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label htmlFor="account_holder_name" className="block text-sm font-medium text-zinc-700 dark:text-zinc-300">
          Account Holder Name
        </label>
        <input
          type="text"
          id="account_holder_name"
          name="account_holder_name"
          value={formData.account_holder_name}
          onChange={handleChange}
          required
          className="mt-1 block w-full rounded-lg border border-zinc-300 px-4 py-2 text-sm text-zinc-900 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500 dark:border-zinc-600 dark:bg-zinc-700 dark:text-zinc-100"
          placeholder="John Doe"
        />
      </div>
      <div>
        <label htmlFor="routing_number" className="block text-sm font-medium text-zinc-700 dark:text-zinc-300">
          Routing Number
        </label>
        <input
          type="text"
          id="routing_number"
          name="routing_number"
          value={formData.routing_number}
          onChange={handleChange}
          required
          pattern="[0-9]{9}"
          className="mt-1 block w-full rounded-lg border border-zinc-300 px-4 py-2 text-sm text-zinc-900 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500 dark:border-zinc-600 dark:bg-zinc-700 dark:text-zinc-100"
          placeholder="110000000"
        />
        <p className="mt-1 text-xs text-zinc-500 dark:text-zinc-400">
          Test routing number: 110000000
        </p>
      </div>
      <div>
        <label htmlFor="account_number" className="block text-sm font-medium text-zinc-700 dark:text-zinc-300">
          Account Number
        </label>
        <input
          type="text"
          id="account_number"
          name="account_number"
          value={formData.account_number}
          onChange={handleChange}
          required
          className="mt-1 block w-full rounded-lg border border-zinc-300 px-4 py-2 text-sm text-zinc-900 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500 dark:border-zinc-600 dark:bg-zinc-700 dark:text-zinc-100"
          placeholder="000123456789"
        />
        <p className="mt-1 text-xs text-zinc-500 dark:text-zinc-400">
          Test account number: 000123456789
        </p>
      </div>
      <div>
        <label htmlFor="confirm_account_number" className="block text-sm font-medium text-zinc-700 dark:text-zinc-300">
          Confirm Account Number
        </label>
        <input
          type="text"
          id="confirm_account_number"
          name="confirm_account_number"
          value={formData.confirm_account_number}
          onChange={handleChange}
          required
          className="mt-1 block w-full rounded-lg border border-zinc-300 px-4 py-2 text-sm text-zinc-900 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500 dark:border-zinc-600 dark:bg-zinc-700 dark:text-zinc-100"
          placeholder="000123456789"
        />
      </div>
      {error && (
        <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
      )}
      <div className="flex gap-3">
        <button
          type="submit"
          disabled={loading || !stripe}
          className="rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 disabled:opacity-50"
        >
          {loading ? "Adding..." : "Add Bank Account"}
        </button>
        <button
          type="button"
          onClick={onCancel}
          disabled={loading}
          className="rounded-lg border border-zinc-300 bg-white px-4 py-2 text-sm font-medium text-zinc-700 hover:bg-zinc-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:border-zinc-600 dark:bg-zinc-700 dark:text-zinc-300"
        >
          Cancel
        </button>
      </div>
    </form>
  );
}
