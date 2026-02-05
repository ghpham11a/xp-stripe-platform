"use client";

import { ReactNode } from "react";
import { StripeProvider } from "./StripeProvider";
import { AccountProvider } from "@/contexts/AccountContext";
import { ToastProvider } from "@/contexts/ToastContext";
import { ErrorBoundary } from "./ErrorBoundary";

interface ProvidersProps {
  children: ReactNode;
}

export function Providers({ children }: ProvidersProps) {
  return (
    <ErrorBoundary>
      <ToastProvider>
        <StripeProvider>
          <AccountProvider>
            {children}
          </AccountProvider>
        </StripeProvider>
      </ToastProvider>
    </ErrorBoundary>
  );
}
