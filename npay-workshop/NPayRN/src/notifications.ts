import { NativeEventEmitter, NativeModules } from 'react-native';
import type { Payment } from './api';

// Lab 5: notifications come from the native side (ios/NPayRN/NPayNotifications.swift).
const native = NativeModules.NPayNotifications;
const emitter = new NativeEventEmitter(native);

/** Shows iOS's permission prompt the first time; resolves true if notifications are allowed. */
export const requestPermission = (): Promise<boolean> => native.requestPermission();

/** "authorized" | "denied" | "notDetermined" | … */
export const getPermissionStatus = (): Promise<string> => native.getPermissionStatus();

/** Lab 6: what a reminder carries, so a tap can open Send money pre-filled. */
export type Reminder = { recipient: string; amount_paise: number };

type TapData = { payment?: Payment; reminder?: Reminder };

/** Lab 6: NPay schedules a notification itself, `seconds` from now (a local notification). */
export const scheduleReminder = (seconds: number, title: string, body: string, data: TapData): Promise<string> =>
  native.scheduleReminder(seconds, title, body, data);

/** The tap that launched the app, if any (once). */
export const getInitialNotification = (): Promise<TapData | null> => native.getInitialNotification();

/** Called whenever the user taps an NPay notification while the app is running. */
export function onNotificationTapped(listener: (data: TapData) => void) {
  return emitter.addListener('notificationTapped', listener);
}
