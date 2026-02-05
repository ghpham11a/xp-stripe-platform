export interface ExternalAccountSummary {
  id: string;
  bank_name: string | null;
  last4: string;
  currency: string;
  default_for_currency: boolean;
}

// Platform Account (with Stripe account and customer IDs)
export interface Account {
  id: string;  // Platform account ID
  stripe_account_id: string;
  stripe_customer_id: string | null;
  email: string | null;
  display_name: string | null;
  created: string;
  is_customer: boolean;
  is_recipient: boolean;
  is_onboarding?: boolean;
  customer_capabilities?: Record<string, unknown>;
  merchant_capabilities?: Record<string, unknown>;
}

// Legacy v1 Account (for backwards compatibility)
export interface LegacyAccount {
  id: string;
  email: string | null;
  business_name: string | null;
  charges_enabled: boolean;
  payouts_enabled: boolean;
  details_submitted: boolean;
  external_accounts: ExternalAccountSummary[];
  created: number;
}

export interface CardDetails {
  brand: string;
  last4: string;
  exp_month: number;
  exp_year: number;
}

export interface PaymentMethod {
  id: string;
  type: string;
  card: CardDetails | null;
  created: number;
}

export interface ExternalAccount {
  id: string;
  object: string;
  bank_name: string | null;
  last4: string;
  routing_number: string | null;
  currency: string;
  country: string;
  default_for_currency: boolean;
  status: string | null;
}

export interface SetupIntentResponse {
  client_secret: string;
  setup_intent_id: string;
  customer_id?: string;
}

export interface UpgradeToMerchantResponse {
  id: string;
  stripe_account_id: string;
  is_merchant: boolean;
  is_recipient: boolean;
  merchant_capabilities: Record<string, unknown>;
  recipient_capabilities: Record<string, unknown>;
}

export interface PayUserRequest {
  amount: number;
  currency?: string;
  recipient_account_id: string;
  payment_method_id: string;
}

export interface PayUserResponse {
  id: string;
  amount: number;
  currency: string;
  status: string;
  recipient: string;
  transfer: string | null;
  created: number;
}

export interface AccountLinkResponse {
  url: string;
  created: string;
  expires_at: string;
}

export interface CreatePaymentIntentRequest {
  amount: number;
  currency?: string;
  recipient_account_id: string;
  save_payment_method: boolean;
}

export interface CreatePaymentIntentResponse {
  client_secret: string;
  payment_intent_id: string;
  amount: number;
  currency: string;
  recipient: string;
}
