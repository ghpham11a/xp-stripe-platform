// Environment variable access with validation (Issue #6)
// Next.js replaces process.env.NEXT_PUBLIC_* at build time, so we must
// reference them directly (not via dynamic property access)

export const env = {
  get STRIPE_PUBLISHABLE_KEY(): string {
    // Direct reference required for Next.js build-time replacement
    const value = process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY;
    if (!value) {
      throw new Error(
        "Missing required environment variable: NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY. " +
        "Please add it to your .env.local file."
      );
    }
    return value;
  },

  get API_URL(): string {
    // Direct reference required for Next.js build-time replacement
    return process.env.NEXT_PUBLIC_API_URL || "http://localhost:6969";
  },
} as const;
