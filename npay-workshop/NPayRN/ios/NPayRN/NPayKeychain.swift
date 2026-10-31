import Foundation
import React
import Security

/// Lab 9 · the iOS Keychain, for JavaScript: small secrets (NPay's refresh token), encrypted by iOS,
/// readable only by this app, and only after the device has been unlocked once since restart.
@objc(NPayKeychain)
final class NPayKeychain: NSObject {
  static let service = "com.npay.workshop"

  @objc static func requiresMainQueueSetup() -> Bool { false }

  /// One Keychain item = class + service + account (our "key").
  private static func query(_ key: String) -> [String: Any] {
    [kSecClass as String: kSecClassGenericPassword,
     kSecAttrService as String: service,
     kSecAttrAccount as String: key]
  }

  @objc func setItem(_ key: String, value: String,
                     resolver resolve: @escaping RCTPromiseResolveBlock,
                     rejecter reject: @escaping RCTPromiseRejectBlock) {
    SecItemDelete(Self.query(key) as CFDictionary)                       // replace, don't duplicate
    var item = Self.query(key)
    item[kSecValueData as String] = Data(value.utf8)
    item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly   // never in backups
    let status = SecItemAdd(item as CFDictionary, nil)
    if status == errSecSuccess { resolve(true) } else { reject("keychain", "SecItemAdd failed: \(status)", nil) }
  }

  @objc func getItem(_ key: String,
                     resolver resolve: @escaping RCTPromiseResolveBlock,
                     rejecter reject: @escaping RCTPromiseRejectBlock) {
    var query = Self.query(key)
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    if status == errSecSuccess, let data = result as? Data {
      resolve(String(data: data, encoding: .utf8))
    } else if status == errSecItemNotFound {
      resolve(nil)
    } else {
      reject("keychain", "SecItemCopyMatching failed: \(status)", nil)
    }
  }

  @objc func removeItem(_ key: String,
                        resolver resolve: @escaping RCTPromiseResolveBlock,
                        rejecter reject: @escaping RCTPromiseRejectBlock) {
    let status = SecItemDelete(Self.query(key) as CFDictionary)
    resolve(status == errSecSuccess || status == errSecItemNotFound)
  }

  /// The Keychain is NOT deleted with the app. On the first launch after an install, remove what an
  /// earlier install left behind (UserDefaults IS deleted with the app, so "installed" missing = fresh install).
  /// Launch argument `-skipFreshInstallCheck YES` turns this off, to show the problem (lab9.md, step 4).
  static func clearOnFreshInstall() {
    let defaults = UserDefaults.standard
    if defaults.bool(forKey: "skipFreshInstallCheck") { return }
    if !defaults.bool(forKey: "installed") {
      SecItemDelete([kSecClass as String: kSecClassGenericPassword,
                     kSecAttrService as String: service] as CFDictionary)
      defaults.set(true, forKey: "installed")
    }
  }
}
