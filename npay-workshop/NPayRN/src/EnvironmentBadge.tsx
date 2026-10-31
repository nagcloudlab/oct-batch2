import React from 'react';
import { StyleSheet, Text } from 'react-native';
import { config } from './config';

/** Shows which environment and server this build uses. Production builds show nothing. */
export function EnvironmentBadge() {
  if (config.environment === 'production') {
    return null;
  }
  return (
    <Text testID="environmentBadge" style={styles.badge}>
      {config.environment.toUpperCase()} · {config.serverURL.replace(/^https?:\/\//, '')}
    </Text>
  );
}

const styles = StyleSheet.create({
  badge: { alignSelf: 'flex-start', backgroundColor: '#fef3c7', color: '#92400e', fontSize: 12, fontWeight: '700', paddingHorizontal: 8, paddingVertical: 3, borderRadius: 6, overflow: 'hidden', marginBottom: 12 },
});
