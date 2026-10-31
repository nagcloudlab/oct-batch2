import React, { useState } from 'react';
import { ActivityIndicator, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { ApiError, signIn } from '../api';
import { colors } from '../theme';
import { EnvironmentBadge } from '../EnvironmentBadge';
import { config } from '../config';

export function SignInScreen({ onSignedIn }: { onSignedIn: () => void }) {
  const [username, setUsername] = useState('asha');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit() {
    setBusy(true);
    setError(null);
    try {
      await signIn(username.trim(), password);
      onSignedIn();
    } catch (e) {
      setError(e instanceof ApiError ? e.message : 'Can’t reach NPay: no connection, or the server couldn’t be verified.');
    } finally {
      setPassword('');   // never kept, success or not
      setBusy(false);
    }
  }

  return (
    <View style={styles.screen}>
      <EnvironmentBadge />
      <Text style={styles.logo}>NPay</Text>
      <Text style={styles.subtitle}>Sign in to your account</Text>
      <TextInput testID="username" style={styles.input} value={username} onChangeText={setUsername}
        placeholder="Username" autoCapitalize="none" autoCorrect={false} />
      <TextInput testID="password" style={styles.input} value={password} onChangeText={setPassword}
        placeholder="Password" secureTextEntry onSubmitEditing={submit} />
      {error && <Text style={styles.error}>{error}</Text>}
      <Pressable testID="signIn" style={[styles.button, (!username || !password || busy) && styles.disabled]}
        disabled={!username || !password || busy} onPress={submit}>
        {busy ? <ActivityIndicator color="#fff" /> : <Text style={styles.buttonText}>Sign in</Text>}
      </Pressable>
      <Text style={styles.version}>Version {config.version} ({config.build})</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, justifyContent: 'center', padding: 24, backgroundColor: colors.bg },
  logo: { fontSize: 40, fontWeight: '800', color: colors.navy },
  subtitle: { fontSize: 16, color: colors.muted, marginBottom: 28 },
  input: { backgroundColor: colors.card, borderWidth: 1, borderColor: colors.border, borderRadius: 12, padding: 14, fontSize: 17, marginBottom: 12 },
  error: { color: colors.error, marginBottom: 12 },
  button: { backgroundColor: colors.teal, borderRadius: 12, padding: 16, alignItems: 'center', marginTop: 4 },
  disabled: { opacity: 0.4 },
  buttonText: { color: '#fff', fontSize: 17, fontWeight: '700' },
  version: { color: colors.muted, fontSize: 13, textAlign: 'center', marginTop: 20 },
});
