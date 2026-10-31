import { NativeModules } from 'react-native';

// Lab 8: the widget and the Live Activity live outside React Native; this native module talks to them
// (ios/NPayRN/NPayWidgetBridge.swift).
const native = NativeModules.NPayWidgetBridge;

/** Shares the balance with the home-screen widget (App Group) and asks iOS to redraw it. */
export const updateWidget = (owner: string, balancePaise: number): void => native.updateBalance(owner, balancePaise);

/** Signed out: the widget must stop showing the balance. */
export const clearWidget = (): void => native.clear();

/** Starts a "payment request" Live Activity counting down `seconds` on the lock screen and Dynamic Island. */
export const startPaymentRequest = (from: string, amountPaise: number, seconds: number): Promise<string> =>
  native.startPaymentRequest(from, amountPaise, seconds);

/** Ends the payment-request Live Activities (the request was paid). */
export const endPaymentRequests = (): void => native.endPaymentRequests();
