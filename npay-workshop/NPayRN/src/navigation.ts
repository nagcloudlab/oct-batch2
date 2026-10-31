import type { Payment } from './api';

// The screens and what each one is given.
export type RootStack = {
  SignIn: undefined;
  Home: undefined;
  Send: { recipient?: string; amountPaise?: number } | undefined;   // Lab 6: a reminder pre-fills it
  PaymentDetail: { payment: Payment; justSent?: boolean };
};
