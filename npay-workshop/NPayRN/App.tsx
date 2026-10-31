/**
 * NPay: the workshop's base app. Plain React Native: four screens talking to the Spring Boot server.
 * Each lab patches one native iOS feature onto this.
 */
import React, { useEffect, useState } from 'react';
import { ActivityIndicator, Linking, Pressable, StatusBar, Text, View } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { NavigationContainer, createNavigationContainerRef } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { Payment, restoreSession, signOut } from './src/api';
import { getInitialNotification, onNotificationTapped, Reminder, requestPermission } from './src/notifications';
import { clearWidget, endPaymentRequests } from './src/widget';
import type { RootStack } from './src/navigation';
import { HomeScreen } from './src/screens/HomeScreen';
import { PaymentDetailScreen } from './src/screens/PaymentDetailScreen';
import { SendScreen } from './src/screens/SendScreen';
import { SignInScreen } from './src/screens/SignInScreen';
import { colors } from './src/theme';

const Stack = createNativeStackNavigator<RootStack>();
const navigation = createNavigationContainerRef<RootStack>();

// Lab 8: npay://send[?to=…&amount=<paise>] from the widget or the Live Activity → Send money (pre-filled)
function fromLink(url: string | null | undefined): { link: { recipient?: string; amountPaise?: number } } | null {
  const m = url?.match(/^npay:\/\/send(?:\?(.*))?$/);
  if (!m) {
    return null;
  }
  const query = new Map((m[1] ?? '').split('&').filter(Boolean).map(kv => kv.split('=').map(decodeURIComponent) as [string, string]));
  const amount = Number(query.get('amount'));
  return { link: { recipient: query.get('to'), amountPaise: amount > 0 ? amount : undefined } };
}

export default function App() {
  const [signedIn, setSignedIn] = useState(false);
  const [restoring, setRestoring] = useState(true);   // Lab 9: checking the Keychain before showing sign-in

  useEffect(() => {
    restoreSession().then(ok => setSignedIn(ok)).finally(() => setRestoring(false));
  }, []);
  const [navReady, setNavReady] = useState(false);
  // Lab 5–6: what a tapped notification carries, waiting until the user is signed in:
  // a payment (Lab 5, the server's "Payment sent") or a reminder (Lab 6, scheduled by the app)
  // Lab 8: or a link (the widget / the Live Activity)
  const [tapped, setTapped] = useState<{ payment?: Payment; reminder?: Reminder; link?: { recipient?: string; amountPaise?: number } } | null>(null);

  useEffect(() => {
    getInitialNotification().then(data => data && setTapped(data));   // the tap that launched the app
    const sub = onNotificationTapped(data => setTapped(data));         // taps while running
    Linking.getInitialURL().then(url => { const t = fromLink(url); if (t) { setTapped(t); } });   // the link that launched the app
    const links = Linking.addEventListener('url', ({ url }) => { const t = fromLink(url); if (t) { setTapped(t); } });
    return () => { sub.remove(); links.remove(); };
  }, []);

  useEffect(() => {
    if (signedIn) {
      requestPermission();   // iOS asks "Allow notifications?" once; later calls return the saved answer
    }
  }, [signedIn]);

  useEffect(() => {
    if (signedIn && navReady && tapped) {
      if (tapped.payment) {
        navigation.navigate('PaymentDetail', { payment: tapped.payment });
      } else if (tapped.reminder) {
        navigation.navigate('Send', { recipient: tapped.reminder.recipient, amountPaise: tapped.reminder.amount_paise });
      } else if (tapped.link) {
        navigation.navigate('Send', tapped.link);
      }
      setTapped(null);
    }
  }, [signedIn, navReady, tapped]);

  if (restoring) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', backgroundColor: colors.bg }}>
        <ActivityIndicator testID="restoring" color={colors.teal} />
      </View>
    );
  }

  return (
    <SafeAreaProvider>
      <StatusBar barStyle="dark-content" />
      <NavigationContainer ref={navigation} onReady={() => setNavReady(true)}>
        <Stack.Navigator screenOptions={{ headerTintColor: colors.teal }}>
          {!signedIn ? (
            <Stack.Screen name="SignIn" options={{ headerShown: false }}>
              {() => <SignInScreen onSignedIn={() => setSignedIn(true)} />}
            </Stack.Screen>
          ) : (
            <>
              <Stack.Screen name="Home" component={HomeScreen} options={{
                title: 'NPay',
                headerRight: () => (
                  <Pressable testID="signOut" onPress={async () => { await signOut(); clearWidget(); endPaymentRequests(); setSignedIn(false); }}>
                    <Text style={{ color: colors.teal, fontSize: 16 }}>Sign out</Text>
                  </Pressable>
                ),
              }} />
              <Stack.Screen name="Send" component={SendScreen} options={{ title: 'Send money' }} />
              <Stack.Screen name="PaymentDetail" component={PaymentDetailScreen} options={{ title: 'Payment' }} />
            </>
          )}
        </Stack.Navigator>
      </NavigationContainer>
    </SafeAreaProvider>
  );
}
