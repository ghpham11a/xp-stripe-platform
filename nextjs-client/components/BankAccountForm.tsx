"use client";

import { useState, useRef } from "react";
import { useStripe } from "@stripe/react-stripe-js";
import { createExternalAccount } from "@/lib/api";
import {
  SUPPORTED_COUNTRIES,
  getCountryConfig,
  validateRoutingNumber,
  validateAccountNumber,
  validateName,
} from "@/lib/validation";

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
  const [country, setCountry] = useState("US");
  const [formData, setFormData] = useState({
    account_holder_name: "",
    routing_number: "",
    account_number: "",
    confirm_account_number: "",
  });
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});

  // Ref to prevent double submissions
  const submittingRef = useRef(false);

  const countryConfig = getCountryConfig(country);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
    // Clear field error when user types
    if (fieldErrors[name]) {
      setFieldErrors((prev) => ({ ...prev, [name]: "" }));
    }
  };

  const handleCountryChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setCountry(e.target.value);
    // Reset routing number when country changes (different formats)
    setFormData((prev) => ({ ...prev, routing_number: "" }));
    setFieldErrors({});
  };

  const validateForm = (): boolean => {
    const errors: Record<string, string> = {};

    const nameValidation = validateName(formData.account_holder_name);
    if (!nameValidation.valid) {
      errors.account_holder_name = nameValidation.error || "Invalid name";
    }

    const routingValidation = validateRoutingNumber(formData.routing_number, country);
    if (!routingValidation.valid) {
      errors.routing_number = routingValidation.error || "Invalid routing number";
    }

    const accountValidation = validateAccountNumber(formData.account_number);
    if (!accountValidation.valid) {
      errors.account_number = accountValidation.error || "Invalid account number";
    }

    if (formData.account_number !== formData.confirm_account_number) {
      errors.confirm_account_number = "Account numbers do not match";
    }

    setFieldErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!stripe) {
      setError("Stripe is not initialized");
      return;
    }

    if (!validateForm()) {
      return;
    }

    // Prevent double submission
    if (submittingRef.current) return;
    submittingRef.current = true;

    setLoading(true);
    setError(null);

    try {
      // Create bank account token using Stripe.js
      const result = await stripe.createToken("bank_account", {
        country: country,
        currency: countryConfig.currency,
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
      submittingRef.current = false;
    }
  };

  const getInputClassName = (fieldName: string) => {
    const hasError = fieldErrors[fieldName];
    return `mt-1 block w-full rounded-lg border px-4 py-2 text-sm text-zinc-900 shadow-sm focus:outline-none focus:ring-1 dark:bg-zinc-700 dark:text-zinc-100 ${
      hasError
        ? "border-red-300 focus:border-red-500 focus:ring-red-500"
        : "border-zinc-300 focus:border-blue-500 focus:ring-blue-500 dark:border-zinc-600"
    }`;
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {/* Country Selection */}
      <div>
        <label htmlFor="country" className="block text-sm font-medium text-zinc-700 dark:text-zinc-300">
          Country
        </label>
        <select
          id="country"
          value={country}
          onChange={handleCountryChange}
          className="mt-1 block w-full rounded-lg border border-zinc-300 bg-white px-4 py-2 text-sm text-zinc-900 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500 dark:border-zinc-600 dark:bg-zinc-700 dark:text-zinc-100"
        >
          {SUPPORTED_COUNTRIES.map((c) => (
            <option key={c.code} value={c.code}>
              {c.name} ({c.currency.toUpperCase()})
            </option>
          ))}
        </select>
      </div>

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
          className={getInputClassName("account_holder_name")}
          placeholder="John Doe"
        />
        {fieldErrors.account_holder_name && (
          <p className="mt-1 text-sm text-red-600 dark:text-red-400">{fieldErrors.account_holder_name}</p>
        )}
      </div>

      <div>
        <label htmlFor="routing_number" className="block text-sm font-medium text-zinc-700 dark:text-zinc-300">
          {country === "GB" ? "Sort Code" : "Routing Number"}
        </label>
        <input
          type="text"
          id="routing_number"
          name="routing_number"
          value={formData.routing_number}
          onChange={handleChange}
          required
          className={getInputClassName("routing_number")}
          placeholder={country === "GB" ? "00-00-00" : "110000000"}
        />
        {fieldErrors.routing_number ? (
          <p className="mt-1 text-sm text-red-600 dark:text-red-400">{fieldErrors.routing_number}</p>
        ) : (
          <p className="mt-1 text-xs text-zinc-500 dark:text-zinc-400">
            {country === "US" && "Test routing number: 110000000"}
            {country === "GB" && "Test sort code: 108800"}
          </p>
        )}
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
          className={getInputClassName("account_number")}
          placeholder="000123456789"
        />
        {fieldErrors.account_number ? (
          <p className="mt-1 text-sm text-red-600 dark:text-red-400">{fieldErrors.account_number}</p>
        ) : (
          <p className="mt-1 text-xs text-zinc-500 dark:text-zinc-400">
            Test account number: 000123456789
          </p>
        )}
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
          className={getInputClassName("confirm_account_number")}
          placeholder="000123456789"
        />
        {fieldErrors.confirm_account_number && (
          <p className="mt-1 text-sm text-red-600 dark:text-red-400">{fieldErrors.confirm_account_number}</p>
        )}
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
