import React, { useEffect, useState } from 'react';
import { ActivityIndicator, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { ApiError, pay } from '../api';
import { scheduleReminder } from '../notifications';
import { endPaymentRequests } from '../widget';
import { formatPaise, parsePaise } from '../money';
import type { RootStack } from '../navigation';
import { colors } from '../theme';

type Props = NativeStackScreenProps<RootStack, 'Send'>;

export function SendScreen({ navigation, route }: Props) {
  // Lab 6: a tapped reminder opens this screen pre-filled
  const [recipient, setRecipient] = useState(route.params?.recipient ?? 'ravi@npay');
  const [amount, setAmount] = useState(route.params?.amountPaise ? (route.params.amountPaise / 100).toFixed(2) : '');
  const [reminderSet, setReminderSet] = useState(false);

  // Lab 6: if this screen is already open when a reminder is tapped, it is reused with new params: refill the form
  useEffect(() => {
    if (route.params?.recipient) {
      setRecipient(route.params.recipient);
    }
    if (route.params?.amountPaise) {
      setAmount((route.params.amountPaise / 100).toFixed(2));
      setReminderSet(false);
    }
  }, [route.params]);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const paise = parsePaise(amount);
  const canPay = !!recipient && paise !== null && !sending;

  // Lab 6: "remind me later": the app schedules its own notification (10 s, so the class can watch it)
  async function remindMe() {
    if (paise === null) {
      return;
    }
    await scheduleReminder(10, 'Payment reminder', `Pay ${formatPaise(paise)} to ${recipient.trim()}`,
      { reminder: { recipient: recipient.trim(), amount_paise: paise } });
    setReminderSet(true);
  }

  async function submit() {
    if (!canPay || paise === null) {
      return;
    }
    setSending(true);   // also stops a double tap
    setError(null);
    try {
      const payment = await pay(recipient.trim(), paise);
      endPaymentRequests();   // Lab 8: a pending request's Live Activity goes away once paid
      navigation.replace('PaymentDetail', { payment, justSent: true });
    } catch (e) {
      setError(e instanceof ApiError ? e.message : 'Can’t reach NPay. Nothing was sent.');
      setSending(false);
    }
  }

  return (
    <View style={styles.screen}>
      <Text style={styles.label}>To</Text>
      <TextInput testID="recipient" style={styles.input} value={recipient} onChangeText={setRecipient}
        autoCapitalize="none" autoCorrect={false} keyboardType="email-address" />
      <Text style={styles.label}>Amount (₹)</Text>
      <TextInput testID="amount" style={styles.input} value={amount} onChangeText={setAmount}
        placeholder="1500.50" keyboardType="decimal-pad" />
      {paise !== null && <Text style={styles.preview}>You are sending {formatPaise(paise)}</Text>}
      {error && <Text style={styles.error}>{error}</Text>}
      <Pressable testID="pay" style={[styles.button, !canPay && styles.disabled]} disabled={!canPay} onPress={submit}>
        {sending ? <ActivityIndicator color="#fff" /> : <Text style={styles.buttonText}>Pay</Text>}
      </Pressable>
      <Pressable testID="remindMe" style={[styles.secondary, !canPay && styles.disabled]} disabled={!canPay} onPress={remindMe}>
        <Text style={styles.secondaryText}>{reminderSet ? 'Reminder set: in 10 seconds' : 'Remind me in 10 seconds'}</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, padding: 20, backgroundColor: colors.bg },
  label: { fontSize: 14, fontWeight: '600', color: colors.muted, marginBottom: 6, marginTop: 8 },
  input: { backgroundColor: colors.card, borderWidth: 1, borderColor: colors.border, borderRadius: 12, padding: 14, fontSize: 18 },
  preview: { marginTop: 14, fontSize: 16, color: colors.text },
  error: { color: colors.error, marginTop: 14 },
  button: { backgroundColor: colors.teal, borderRadius: 12, padding: 16, alignItems: 'center', marginTop: 24 },
  disabled: { opacity: 0.4 },
  buttonText: { color: '#fff', fontSize: 17, fontWeight: '700' },
  secondary: { borderRadius: 12, padding: 14, alignItems: 'center', marginTop: 12, borderWidth: 1, borderColor: colors.teal },
  secondaryText: { color: colors.teal, fontSize: 16, fontWeight: '600' },
});
