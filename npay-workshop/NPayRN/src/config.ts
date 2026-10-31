import { NativeModules } from 'react-native';

// Lab 3: which server this build talks to comes from the native side (Info.plist, set per Xcode
// build configuration), through the AppConfig native module (ios/NPayRN/AppConfig.swift).
type AppConfigModule = { environment: string; serverURL: string; version: string; build: string };

const native: AppConfigModule | undefined = NativeModules.AppConfig?.getConstants?.() ?? NativeModules.AppConfig;

if (!native?.serverURL) {
  // fail loudly: a build that silently talks to the wrong server is worse than one that doesn't start
  throw new Error('AppConfig native module missing: rebuild the iOS app (Lab 3 adds it)');
}

export const config = {
  environment: native.environment,   // "development" | "staging" | "production"
  serverURL: native.serverURL,
  version: native.version,
  build: native.build,
};
