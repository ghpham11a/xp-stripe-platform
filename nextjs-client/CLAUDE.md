# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

For overall project architecture, Stripe v2 Accounts model, API endpoints, and backend details, see the parent `../CLAUDE.md`.

## Development Commands

```bash
npm run dev     # Start dev server on port 3000
npm run build   # Production build
npm run lint    # Run ESLint
```

## Environment Variables

Create `.env.local` with:
- `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` - Stripe publishable key (required)
- `NEXT_PUBLIC_API_URL` - Backend URL (defaults to `http://localhost:6969`)

## Architecture

### Provider Hierarchy

The app wraps all pages in a provider chain configured in `components/Providers.tsx`:
```
StripeProvider (Elements context)
  └── AccountProvider (global account state)
```

### Routing Structure

Uses Next.js App Router with dynamic `[id]` segments:
- `/` - Account selector and navigation cards
- `/accounts/[id]` - Account details page with pay-user and upgrade-to-recipient
- `/accounts/[id]/payment-methods` - Card management with SetupIntent flow
- `/accounts/[id]/bank-accounts` - External bank account management

The `/accounts/[id]/layout.tsx` syncs the URL param with `AccountContext` and provides shared header/navigation.

### State Management

`contexts/AccountContext.tsx` provides global state for:
- `accounts` - list of all accounts
- `selectedAccountId` / `selectedAccount` - current account selection
- `fetchAccounts()` / `fetchAccountDetails()` - data fetching
- `addAccount()` / `deleteAccount()` - mutations

Components access this via the `useAccount()` hook.

### API Client

`lib/api.ts` exports typed functions for all backend endpoints. All functions use `handleResponse<T>()` for error handling and JSON parsing.

### Stripe Integration

SetupIntents and PaymentIntents are created server-side, then confirmed client-side using `@stripe/react-stripe-js` Elements. The platform's publishable key is used (not the connected account's).

## Test Data

- **Test Card**: `4242 4242 4242 4242`, any future expiry, any CVC
- **Test Bank**: Routing `110000000`, Account `000123456789`
