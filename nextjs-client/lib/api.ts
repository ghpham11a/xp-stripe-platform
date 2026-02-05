import type {
  Account,
  PaymentMethod,
  ExternalAccount,
  SetupIntentResponse,
  UpgradeToMerchantResponse,
  PayUserResponse,
  AccountLinkResponse,
  CreatePaymentIntentResponse,
} from "./types";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:6969";

async function handleResponse<T>(response: Response): Promise<T> {
  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: "Unknown error" }));
    throw new Error(error.detail || `HTTP ${response.status}`);
  }
  return response.json();
}

// Account APIs
export async function createAccount(
  name: string,
  email: string,
  country: string = "US"
): Promise<Account> {
  const response = await fetch(`${API_URL}/api/accounts`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      name,
      email,
      country,
    }),
  });
  return handleResponse<Account>(response);
}

export async function listAccounts(): Promise<Account[]> {
  const response = await fetch(`${API_URL}/api/accounts`);
  const data = await handleResponse<{ accounts: Account[] }>(response);
  return data.accounts;
}

export async function getAccount(accountId: string): Promise<Account> {
  const response = await fetch(`${API_URL}/api/accounts/${accountId}`);
  return handleResponse<Account>(response);
}

export async function deleteAccount(accountId: string): Promise<void> {
  const response = await fetch(`${API_URL}/api/accounts/${accountId}`, {
    method: "DELETE",
  });
  await handleResponse(response);
}

// Payment Method APIs
export async function createSetupIntent(
  accountId: string,
  customerId?: string | null
): Promise<SetupIntentResponse> {
  const params = customerId ? `?customer_id=${encodeURIComponent(customerId)}` : "";
  const response = await fetch(
    `${API_URL}/api/accounts/${accountId}/payment-methods/setup-intent${params}`,
    { method: "POST" }
  );
  return handleResponse<SetupIntentResponse>(response);
}

export async function listPaymentMethods(
  accountId: string
): Promise<PaymentMethod[]> {
  const response = await fetch(
    `${API_URL}/api/accounts/${accountId}/payment-methods`
  );
  const data = await handleResponse<{ payment_methods: PaymentMethod[] }>(
    response
  );
  return data.payment_methods;
}

export async function deletePaymentMethod(
  accountId: string,
  paymentMethodId: string
): Promise<void> {
  const response = await fetch(
    `${API_URL}/api/accounts/${accountId}/payment-methods/${paymentMethodId}`,
    { method: "DELETE" }
  );
  await handleResponse(response);
}

// External Account APIs
export async function createExternalAccount(
  accountId: string,
  token: string
): Promise<ExternalAccount> {
  const response = await fetch(
    `${API_URL}/api/accounts/${accountId}/external-accounts`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ token }),
    }
  );
  return handleResponse<ExternalAccount>(response);
}

export async function listExternalAccounts(
  accountId: string
): Promise<ExternalAccount[]> {
  const response = await fetch(
    `${API_URL}/api/accounts/${accountId}/external-accounts`
  );
  const data = await handleResponse<{ external_accounts: ExternalAccount[] }>(
    response
  );
  return data.external_accounts;
}

export async function deleteExternalAccount(
  accountId: string,
  externalAccountId: string
): Promise<void> {
  const response = await fetch(
    `${API_URL}/api/accounts/${accountId}/external-accounts/${externalAccountId}`,
    { method: "DELETE" }
  );
  await handleResponse(response);
}

export async function setDefaultExternalAccount(
  accountId: string,
  externalAccountId: string
): Promise<ExternalAccount> {
  const response = await fetch(
    `${API_URL}/api/accounts/${accountId}/external-accounts/${externalAccountId}/default`,
    { method: "PATCH" }
  );
  return handleResponse<ExternalAccount>(response);
}

// Upgrade account to merchant
export async function upgradeToMerchant(
  accountId: string
): Promise<UpgradeToMerchantResponse> {
  const response = await fetch(
    `${API_URL}/api/accounts/${accountId}/upgrade-to-recipient`,
    { method: "POST" }
  );
  return handleResponse<UpgradeToMerchantResponse>(response);
}

// Pay another user (destination charge)
export async function payUser(
  accountId: string,
  recipientAccountId: string,
  paymentMethodId: string,
  amount: number,
  currency: string = "usd"
): Promise<PayUserResponse> {
  const response = await fetch(
    `${API_URL}/api/transactions/${accountId}/pay-user`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        amount,
        currency,
        recipient_account_id: recipientAccountId,
        payment_method_id: paymentMethodId,
      }),
    }
  );
  return handleResponse<PayUserResponse>(response);
}

// Create onboarding link for merchant signup
export async function createOnboardingLink(
  accountId: string,
  refreshUrl: string,
  returnUrl: string
): Promise<AccountLinkResponse> {
  const response = await fetch(
    `${API_URL}/api/accounts/${accountId}/onboarding-link`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        refresh_url: refreshUrl,
        return_url: returnUrl,
      }),
    }
  );
  return handleResponse<AccountLinkResponse>(response);
}

// Create PaymentIntent for paying a user with a new card
export async function createPaymentIntent(
  accountId: string,
  recipientAccountId: string,
  amount: number,
  savePaymentMethod: boolean,
  currency: string = "usd"
): Promise<CreatePaymentIntentResponse> {
  const response = await fetch(
    `${API_URL}/api/transactions/${accountId}/create-payment-intent`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        amount,
        currency,
        recipient_account_id: recipientAccountId,
        save_payment_method: savePaymentMethod,
      }),
    }
  );
  return handleResponse<CreatePaymentIntentResponse>(response);
}
