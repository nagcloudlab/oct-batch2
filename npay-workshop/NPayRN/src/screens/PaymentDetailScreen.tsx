import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { formatPaise } from '../money';
import type { RootStack } from '../navigation';
import { colors } from '../theme';

type Props = NativeStackScreenProps<RootStack, 'PaymentDetail'>;

export function PaymentDetailScreen({ route, navigation }: Props) {
  const { payment, justSent } = route.params;
  const rows: [string, string][] = [
    ['To', payment.recipient],
    ['When', new Date(payment.created_at).toLocaleString('en-IN')],
    ['Balance after', formatPaise(payment.balance_after_paise)],
    ['Payment id', payment.id],
  ];
  return (
    <View style={styles.screen}>
      {justSent && <Text testID="sent" style={styles.sent}>✓ Sent</Text>}
      <Text style={styles.amount}>{formatPaise(payment.amount_paise)}</Text>
      <View style={styles.card}>
        {rows.map(([k, v]) => (
          <View key={k} style={styles.row}>
            <Text style={styles.key}>{k}</Text>
            <Text style={styles.value}>{v}</Text>
          </View>
        ))}
      </View>
      {justSent && (
        <Pressable testID="done" style={styles.button} onPress={() => navigation.popToTop()}>
          <Text style={styles.buttonText}>Done</Text>
        </Pressable>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, padding: 20, backgroundColor: colors.bg },
  sent: { fontSize: 18, fontWeight: '700', color: colors.teal, marginBottom: 6 },
  amount: { fontSize: 40, fontWeight: '800', color: colors.navy, marginBottom: 18 },
  card: { backgroundColor: colors.card, borderRadius: 14, borderWidth: 1, borderColor: colors.border },
  row: { flexDirection: 'row', justifyContent: 'space-between', padding: 14, borderBottomWidth: 1, borderBottomColor: colors.border },
  key: { color: colors.muted, fontSize: 15 },
  value: { color: colors.text, fontSize: 15, fontWeight: '600' },
  button: { backgroundColor: colors.teal, borderRadius: 12, padding: 16, alignItems: 'center', marginTop: 24 },
  buttonText: { color: '#fff', fontSize: 17, fontWeight: '700' },
});
