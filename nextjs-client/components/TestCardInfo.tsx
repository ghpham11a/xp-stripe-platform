"use client";

export function TestCardInfo() {
  return (
    <div className="mt-8 rounded-lg bg-blue-50 p-4 dark:bg-blue-900/20">
        <h4 className="text-sm font-medium text-blue-900 dark:text-blue-100">
          Test Data
        </h4>
        <div className="mt-2 space-y-1 text-sm text-blue-700 dark:text-blue-300">
          <p>
            <strong>Test Card:</strong> 4242 4242 4242 4242, any future date, any CVC
          </p>
          <p>
            <strong>Test Bank:</strong> Routing: 110000000, Account: 000123456789
          </p>
        </div>
      </div>
  );
}