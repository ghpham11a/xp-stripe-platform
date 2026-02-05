// Input validation utilities (Issue #5)

export const PAYMENT_LIMITS = {
  MIN_AMOUNT_CENTS: 50, // Stripe minimum is $0.50
  MAX_AMOUNT_CENTS: 99999999, // $999,999.99
  MIN_AMOUNT_DISPLAY: 0.5,
  MAX_AMOUNT_DISPLAY: 999999.99,
} as const;

export const SUPPORTED_COUNTRIES = [
  { code: "US", name: "United States", currency: "usd" },
  { code: "GB", name: "United Kingdom", currency: "gbp" },
  { code: "CA", name: "Canada", currency: "cad" },
  { code: "AU", name: "Australia", currency: "aud" },
  { code: "DE", name: "Germany", currency: "eur" },
  { code: "FR", name: "France", currency: "eur" },
  { code: "NL", name: "Netherlands", currency: "eur" },
] as const;

export type SupportedCountryCode = typeof SUPPORTED_COUNTRIES[number]["code"];
export type SupportedCurrency = typeof SUPPORTED_COUNTRIES[number]["currency"];

export function getCountryConfig(countryCode: string) {
  return SUPPORTED_COUNTRIES.find((c) => c.code === countryCode) || SUPPORTED_COUNTRIES[0];
}

export interface ValidationResult {
  valid: boolean;
  error?: string;
}

export function validateAmount(amountStr: string): ValidationResult {
  if (!amountStr || amountStr.trim() === "") {
    return { valid: false, error: "Amount is required" };
  }

  const amount = parseFloat(amountStr);

  if (isNaN(amount)) {
    return { valid: false, error: "Invalid amount" };
  }

  if (amount < PAYMENT_LIMITS.MIN_AMOUNT_DISPLAY) {
    return { valid: false, error: `Minimum amount is $${PAYMENT_LIMITS.MIN_AMOUNT_DISPLAY.toFixed(2)}` };
  }

  if (amount > PAYMENT_LIMITS.MAX_AMOUNT_DISPLAY) {
    return { valid: false, error: `Maximum amount is $${PAYMENT_LIMITS.MAX_AMOUNT_DISPLAY.toLocaleString()}` };
  }

  // Check for too many decimal places
  const decimalParts = amountStr.split(".");
  if (decimalParts.length > 1 && decimalParts[1].length > 2) {
    return { valid: false, error: "Amount cannot have more than 2 decimal places" };
  }

  return { valid: true };
}

export function validateEmail(email: string): ValidationResult {
  if (!email || email.trim() === "") {
    return { valid: false, error: "Email is required" };
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return { valid: false, error: "Invalid email format" };
  }

  return { valid: true };
}

export function validateName(name: string): ValidationResult {
  if (!name || name.trim() === "") {
    return { valid: false, error: "Name is required" };
  }

  if (name.trim().length < 2) {
    return { valid: false, error: "Name must be at least 2 characters" };
  }

  if (name.trim().length > 100) {
    return { valid: false, error: "Name must be less than 100 characters" };
  }

  return { valid: true };
}

export function validateRoutingNumber(routing: string, country: string): ValidationResult {
  if (!routing || routing.trim() === "") {
    return { valid: false, error: "Routing number is required" };
  }

  // US routing numbers are 9 digits
  if (country === "US") {
    if (!/^\d{9}$/.test(routing)) {
      return { valid: false, error: "US routing number must be 9 digits" };
    }
  }

  // UK sort codes are 6 digits
  if (country === "GB") {
    if (!/^\d{6}$/.test(routing.replace(/-/g, ""))) {
      return { valid: false, error: "UK sort code must be 6 digits" };
    }
  }

  return { valid: true };
}

export function validateAccountNumber(accountNumber: string): ValidationResult {
  if (!accountNumber || accountNumber.trim() === "") {
    return { valid: false, error: "Account number is required" };
  }

  if (!/^\d+$/.test(accountNumber)) {
    return { valid: false, error: "Account number must contain only digits" };
  }

  if (accountNumber.length < 4 || accountNumber.length > 17) {
    return { valid: false, error: "Account number must be between 4 and 17 digits" };
  }

  return { valid: true };
}

// Debounce utility for preventing rapid submissions (Issue #9)
export function debounce<T extends (...args: Parameters<T>) => ReturnType<T>>(
  func: T,
  wait: number
): (...args: Parameters<T>) => void {
  let timeoutId: ReturnType<typeof setTimeout> | null = null;

  return (...args: Parameters<T>) => {
    if (timeoutId) {
      clearTimeout(timeoutId);
    }
    timeoutId = setTimeout(() => {
      func(...args);
    }, wait);
  };
}
