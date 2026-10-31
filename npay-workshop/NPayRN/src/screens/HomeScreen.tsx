import React, { useCallback, useState } from 'react';
import { FlatList, Pressable, RefreshControl, StyleSheet, Text, View } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { Account, getAccount, getPayments, Payment } from '../api';
import { formatPaise } from '../money';
import type { RootStack } from '../navigation';
import { colors } from '../theme';
import { EnvironmentBadge } from '../EnvironmentBadge';
import { startPaymentRequest, updateWidget } from '../widget';

type Props = NativeStackScreenProps<RootStack, 'Home'>;

export function HomeScreen({ navigation }: Props) {
  const [account, setAccount] = useState<Account | null>(null);
  const [payments, setPayments] = useState<Payment[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [a, p] = await Promise.all([getAccount(), getPayments()]);
      setAccount(a);
      setPayments(p);
      updateWidget(a.owner, a.balance_paise);   // Lab 8: the home-screen widget shows the same balance
    } catch {
      setError('Couldn’t load your account. Pull to try again.');
    } finally {
      setLoading(false);
    }
  }, []);

  // reload every time Home comes back into view (e.g. after a payment)
  useFocusEffect(useCallback(() => { load(); }, [load]));

  return (
    <FlatList
      style={styles.screen}
      contentContainerStyle={styles.content}
      data={payments}
      keyExtractor={p => p.id}
      refreshControl={<RefreshControl refreshing={loading} onRefresh={load} />}
      ListHeaderComponent={
        <View>
          <EnvironmentBadge />
          <View style={styles.balanceCard} testID="balanceCard">
            <Text style={styles.balanceLabel}>Available balance</Text>
            <Text style={styles.balance}>{account ? formatPaise(account.balance_paise) : '—'}</Text>
            <Text style={styles.owner}>{account?.owner ?? ''}</Text>
          </View>
          <Pressable testID="sendMoney" style={styles.send} onPress={() => navigation.navigate('Send')}>
            <Text style={styles.sendText}>Send money</Text>
          </Pressable>
          <Pressable testID="paymentRequest" style={styles.demo}
            onPress={() => startPaymentRequest('ravi@npay', 50000, 300).catch(e => setError(e.message))}>
            <Text style={styles.demoText}>Demo: ravi@npay requests ₹500 (5 min)</Text>
          </Pressable>
          {error && <Text style={styles.error}>{error}</Text>}
          <Text style={styles.section}>Recent payments</Text>
        </View>
      }
      renderItem={({ item }) => (
        <Pressable style={styles.row} onPress={() => navigation.navigate('PaymentDetail', { payment: item })}>
          <View>
            <Text style={styles.recipient}>{item.recipient}</Text>
            <Text style={styles.date}>{new Date(item.created_at).toLocaleString('en-IN')}</Text>
          </View>
          <Text style={styles.amount}>−{formatPaise(item.amount_paise)}</Text>
        </Pressable>
      )}
    />
  );
}

const styles = StyleSheet.create({
  screen: { backgroundColor: colors.bg },
  content: { padding: 16 },
  balanceCard: { backgroundColor: colors.navy, borderRadius: 20, padding: 22 },
  balanceLabel: { color: '#94a3b8', fontSize: 14 },
  balance: { color: '#fff', fontSize: 38, fontWeight: '800', marginVertical: 6 },
  owner: { color: '#5eead4', fontSize: 15 },
  send: { backgroundColor: colors.teal, borderRadius: 12, padding: 15, alignItems: 'center', marginTop: 14 },
  sendText: { color: '#fff', fontSize: 17, fontWeight: '700' },
  error: { color: colors.error, marginTop: 12 },
  demo: { borderRadius: 12, padding: 12, alignItems: 'center', marginTop: 10, borderWidth: 1, borderColor: colors.teal },
  demoText: { color: colors.teal, fontSize: 15, fontWeight: '600' },
  section: { fontSize: 15, fontWeight: '700', color: colors.muted, marginTop: 24, marginBottom: 8 },
  row: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', backgroundColor: colors.card, borderRadius: 12, padding: 14, marginBottom: 8, borderWidth: 1, borderColor: colors.border },
  recipient: { fontSize: 16, fontWeight: '600', color: colors.text },
  date: { fontSize: 13, color: colors.muted, marginTop: 2 },
  amount: { fontSize: 16, fontWeight: '700', color: colors.text },
});
