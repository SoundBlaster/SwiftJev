# iOS Keychain Runbook for SwiftJev

This runbook shows how an iOS app can store a **user-provided** TypeSafe API key in the Keychain and pass it to `JevDecisionBackend`. SwiftJev supports iOS 15 and later.

## Choose the credential model first

Do not put a shared TypeSafe API key in the app source, `Info.plist`, an asset catalog, or the app's configuration. A value embedded in a distributed app can be extracted; storing that same shared value in Keychain does not make it a server-side secret.

The local Keychain approach below is for an app where each user supplies their own key. If the app uses an account owned by your service, keep the TypeSafe key on your server and have the app call your authenticated backend. Add rate limits and authorization there.

## Store, read, and delete the key

Use a generic-password Keychain item. `WhenUnlockedThisDeviceOnly` makes the item available while the device is unlocked and prevents it from migrating to another device in a backup restore. Choose a different accessibility class only when the app's background behavior requires it. See Apple's documentation for [`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`](https://developer.apple.com/documentation/security/ksecattraccessiblewhenunlockedthisdeviceonly) and [restricting Keychain item accessibility](https://developer.apple.com/documentation/security/restricting-keychain-item-accessibility).

```swift
import Foundation
import Security

enum APIKeyKeychainError: Error {
    case emptyKey
    case operationFailed(OSStatus)
    case invalidStoredValue
}

enum TypeSafeAPIKeyStore {
    private static let service = Bundle.main.bundleIdentifier ?? "com.example.MyApp"
    private static let account = "typesafe-api-key"

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    static func save(_ apiKey: String) throws {
        guard !apiKey.isEmpty else { throw APIKeyKeychainError.emptyKey }

        let data = Data(apiKey.utf8)
        let updates: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, updates as CFDictionary)

        if updateStatus == errSecItemNotFound {
            var item = baseQuery
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            let addStatus = SecItemAdd(item as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw APIKeyKeychainError.operationFailed(addStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw APIKeyKeychainError.operationFailed(updateStatus)
        }
    }

    static func load() throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw APIKeyKeychainError.operationFailed(status)
        }
        guard let data = result as? Data, let apiKey = String(data: data, encoding: .utf8) else {
            throw APIKeyKeychainError.invalidStoredValue
        }
        return apiKey
    }

    static func delete() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw APIKeyKeychainError.operationFailed(status)
        }
    }
}
```

Use a `SecureField` for key entry, call `save` after explicit user action, and clear the in-memory text field after saving. Do not log the key or include it in analytics or crash reports.

## Create the Jev backend

Load the key when the app needs to make a decision. A missing key should lead to a credential-entry flow, not a hard-coded fallback.

```swift
import SwiftDecision
import SwiftJev

func classify(_ requestSummary: String) async throws {
    guard let apiKey = try TypeSafeAPIKeyStore.load() else {
        // Present the app's secure credential-entry flow.
        return
    }

    let backend = try JevDecisionBackend(apiKey: apiKey)
    let engine = DecisionEngine(backend: backend)
    let result = try await engine.noul(
        statement: "Should this request be escalated?",
        context: requestSummary
    )
    print(result.value as Any, result.probabilities)
}
```

Delete the Keychain item when the user signs out or chooses to remove the credential:

```swift
try TypeSafeAPIKeyStore.delete()
```

Keep the key scoped to the app's Keychain service and account. Avoid synchronizing a provider credential to iCloud unless that behavior is an intentional product requirement.
