// TEMPORARY: drives the real app code for screenshots (no taps available from the shell). Removed after capture.
import type { NavigationContainerRef } from '@react-navigation/native';
import { BASE_URL, pay, signIn } from './api';
import type { RootStack } from './navigation';

const wait = (ms: number) => new Promise<void>(r => setTimeout(() => r(), ms));
const step = (n: string) => { fetch(`${BASE_URL}/v1/autopilot/${encodeURIComponent(n)}`).catch(() => {}); };   // shows in the server log

export async function autopilot(nav: NavigationContainerRef<RootStack>, setSignedIn: (v: boolean) => void) {
  step('signin-screen'); await wait(5000);
  try { await signIn('asha', 'wrong'); } catch (e: any) { step(`wrong-password ${e.code} ${e.message}`); }
  await signIn('asha', 'npay-demo'); setSignedIn(true);
  await wait(2500); step('home'); await wait(5000);
  nav.navigate('Send'); await wait(2500); step('send'); await wait(5000);
  const p = await pay('ravi@npay', 150050);
  nav.navigate('PaymentDetail', { payment: p, justSent: true }); await wait(2500); step(`sent ${p.id} ${p.balance_after_paise}`); await wait(5000);
  nav.dispatch({ type: 'POP_TO_TOP' }); await wait(3000); step('home-after'); await wait(5000);
  try { await pay('ravi@npay', 9_000_000); } catch (e: any) { step(`over-balance ${e.code} ${e.message}`); }
  step('done');
}
