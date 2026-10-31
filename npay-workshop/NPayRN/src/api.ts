import { NativeModules } from 'react-native';
import { config } from './config';

// Lab 9: the refresh token lives in the iOS Keychain (ios/NPayRN/NPayKeychain.swift); the access token only in memory.
const keychain = NativeModules.NPayKeychain;
const REFRESH_TOKEN = 'refreshToken';
type Tokens = { access_token: string; refresh_token: string };

// The NPay server (Spring Boot, ../server), chosen by the build configuration (Lab 3):
// Debug → development, Staging → staging, Release → production. The Simulator reaches the Mac's localhost.
export const BASE_URL = config.serverURL;

export type Account = { id: string; owner: string; balance_paise: number; currency: string; updated_at: string };
export type Payment = { id: string; recipient: string; amount_paise: number; balance_after_paise: number; created_at: string };

export class ApiError extends Error {
  constructor(public status: number, public code: string, message: string) {
    super(message);
  }
}

let accessToken: string | null = null;

async function call<T>(path: string, init: RequestInit = {}): Promise<T> {
  const headers: Record<string, string> = { 'Content-Type': 'application/json', ...(init.headers as Record<string, string>) };
  if (accessToken) {
    headers.Authorization = `Bearer ${accessToken}`;
  }
  const res = await fetch(BASE_URL + path, { ...init, headers });
  const body = res.status === 204 ? null : await res.json();
  if (!res.ok) {
    throw new ApiError(res.status, body?.error?.code ?? 'unknown', body?.error?.message ?? `HTTP ${res.status}`);
  }
  return body as T;
}

export async function signIn(username: string, password: string): Promise<void> {
  const tokens = await call<Tokens>('/v1/login', {
    method: 'POST',
    body: JSON.stringify({ username, password }),
  });
  accessToken = tokens.access_token;                         // memory only: short-lived
  await keychain.setItem(REFRESH_TOKEN, tokens.refresh_token);   // Keychain: survives app restarts
}

/** Lab 9: at launch, trade the stored refresh token for a new session. true = signed in. */
export async function restoreSession(): Promise<boolean> {
  const refresh: string | null = await keychain.getItem(REFRESH_TOKEN);
  if (!refresh) {
    return false;
  }
  try {
    const tokens = await call<Tokens>('/v1/token', { method: 'POST', body: JSON.stringify({ refresh_token: refresh }) });
    accessToken = tokens.access_token;
    await keychain.setItem(REFRESH_TOKEN, tokens.refresh_token);   // the server rotates it: keep the new one
    return true;
  } catch (e) {
    if (e instanceof ApiError && e.status === 401) {
      await keychain.removeItem(REFRESH_TOKEN);   // revoked or expired: forget it, sign in again
    }
    return false;                                 // offline: keep it, try again next launch
  }
}

/** Revokes the refresh token on the server (best effort) and forgets it on the phone. */
export async function signOut(): Promise<void> {
  const refresh: string | null = await keychain.getItem(REFRESH_TOKEN);
  if (refresh) {
    await call('/v1/logout', { method: 'POST', body: JSON.stringify({ refresh_token: refresh }) }).catch(() => {});
  }
  accessToken = null;
  await keychain.removeItem(REFRESH_TOKEN);
}

export const getAccount = () => call<Account>('/v1/account');
export const getPayments = () => call<{ payments: Payment[] }>('/v1/payments').then(r => r.payments);

export function pay(recipient: string, amountPaise: number): Promise<Payment> {
  const key = `npay-${Date.now()}-${Math.random().toString(36).slice(2)}`;   // a retry never charges twice
  return call<Payment>('/v1/payments', {
    method: 'POST',
    headers: { 'Idempotency-Key': key },
    body: JSON.stringify({ recipient, amount_paise: amountPaise }),
  });
}
