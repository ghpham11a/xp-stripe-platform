# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Stripe Connect demo application with a Python FastAPI backend and Next.js frontend. It demonstrates managing **Stripe v2 Core Accounts** with customer/recipient configurations, payment methods (via SetupIntents), destination charges, and onboarding flows.

## Development Commands

### Backend (FastAPI - Python)

```bash
cd server
.\env\Scripts\activate  # Windows
source env/bin/activate  # Unix

uvicorn app.main:app --host 0.0.0.0 --port 6969 --reload
```

### Frontend (Next.js)

```bash
cd nextjs-client
npm run dev     # Start dev server on port 3000
npm run build   # Production build
npm run lint    # Run ESLint
```

## Environment Variables

### Backend (`server/app/.env`)
- `STRIPE_SECRET_KEY` - Stripe secret API key (required)

### Frontend (`nextjs-client/.env.local`)
- `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` - Stripe publishable key (required)
- `NEXT_PUBLIC_API_URL` - Backend URL (defaults to `http://localhost:6969`)

## Architecture

### Stripe v2 Accounts Model

The backend uses **Stripe v2 Core Accounts API** (`stripe_client.v2.core.accounts`), not the v1 connected accounts API. Key differences:

- Accounts have **configurations**: `customer`, `merchant`, `recipient`
- Accounts start as `customer` and can be upgraded to `recipient`
- Recipient configuration requires: `dashboard`, `defaults.responsibilities.losses_collector`, `defaults.responsibilities.fees_collector`
- Uses `stripe_version="2025-12-15.preview"` for recipient capabilities
- Onboarding uses `v2.core.account_links` API

Account states tracked via:
- `is_customer`, `is_recipient` - which configurations are applied
- `is_onboarding` - true if `stripe_balance.payouts` or `stripe_balance.stripe_transfers` status is "restricted"

### Backend Structure (`server/app/`)

- `main.py` - FastAPI app factory with CORS and router registration
- `routers/accounts.py` - v2 Account CRUD, upgrade-to-recipient, onboarding links
- `routers/payment_methods.py` - SetupIntent creation and payment method management
- `routers/transactions.py` - Destination charges (pay-user) and PaymentIntent creation
- `routers/external_accounts.py` - Bank account endpoints (v1 API)
- `services/stripe_service.py` - Stripe API wrappers (mixed v1/v2)
- `services/database.py` - JSON file-based mock database (`data/accounts.json`)
- `schemas/` - Pydantic models for request/response validation

### Frontend Structure (`nextjs-client/`)

- `app/page.tsx` - Main dashboard with account management, onboarding flow, payment methods
- `components/PaymentMethodForm.tsx` - Stripe Elements with SetupIntent flow
- `components/PayUserForm.tsx` - Pay another user with destination charges
- `lib/api.ts` - API client functions
- `lib/types.ts` - TypeScript interfaces

### Payment Methods Flow

SetupIntents are created at **platform level** (not on connected account) with `account_id` stored in metadata. Customers are looked up via `metadata['account_id']` search. This allows using the platform's publishable key on the frontend.

### Destination Charges Flow

The `/api/transactions/{account_id}/pay-user` endpoint creates PaymentIntents with `transfer_data.destination` to send funds to a recipient. A 10% application fee is collected by the platform.

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/accounts` | Create v2 customer account |
| GET | `/api/accounts` | List accounts with customer config |
| GET | `/api/accounts/{id}` | Get account with capabilities status |
| DELETE | `/api/accounts/{id}` | Delete account |
| POST | `/api/accounts/{id}/upgrade-to-recipient` | Add recipient configuration |
| POST | `/api/accounts/{id}/onboarding-link` | Create account onboarding link |
| POST | `/api/accounts/{id}/payment-methods/setup-intent` | Create SetupIntent |
| GET | `/api/accounts/{id}/payment-methods` | List payment methods |
| DELETE | `/api/accounts/{id}/payment-methods/{pm_id}` | Detach payment method |
| POST | `/api/transactions/{id}/pay-user` | Destination charge to pay another user |
| POST | `/api/transactions/{id}/create-payment-intent` | Create PaymentIntent for new card payment |

## Test Data

- **Test Card**: `4242 4242 4242 4242`, any future expiry, any CVC
- **Test Bank**: Routing `110000000`, Account `000123456789`
