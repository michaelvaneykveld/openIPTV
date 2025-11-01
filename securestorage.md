Below is a **production‑grade, cross‑platform plan** for storing credentials in your modular Flutter IPTV app (Xtream, Stalker/Ministra, M3U/XMLTV). It focuses on **least privilege**, **separation of secrets**, **OS‑level secure stores**, **no accidental logging**, and **clean ergonomics for developers**.

---

## 1) What you must protect (and how much)

| Provider             | Secret(s)                                                   | Notes                                                                                                                             |
| -------------------- | ----------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| **Xtream**           | `username`, `password`                                      | These often end up in query params of playlist/API URLs — **never** persist full URLs with embedded creds. Build them at runtime. |
| **Stalker/Ministra** | `token` (from handshake), sometimes `mac` (identity)        | Treat token as a secret. MAC is not a secret but link it to the token entry so you can rotate tokens safely.                      |
| **M3U/XMLTV**        | Playlist URL may include `username`/`password` or **token** | Split base URL from secrets. Consider separate EPG URL (usually non‑secret).                                                      |

General rule: **Store only what you need**. Prefer **short‑lived tokens** over passwords. For Xtream, some servers don’t issue tokens, so password storage is unavoidable—use the OS key vault.

---

## 2) Storage primitives by platform (use the OS vault)

Use **`flutter_secure_storage`** as your single abstraction. It maps to:

* **Android**: Encrypted Shared Preferences + **Android Keystore** (Tink) with non‑exportable keys. Keys can enforce user authentication policies. ([GitHub][1])
* **iOS / macOS**: **Keychain Services**, an encrypted system database for small secrets; supports access control & biometrics. ([Apple Developer][2])
* **Windows**: **Credential Manager / DPAPI** under the hood. ([Microsoft Learn][3])
* **Linux**: **libsecret/Secret Service** (e.g., GNOME Keyring / KWallet). ([GitHub][4])
* **Web**: Uses **LocalStorage** with WebCrypto wrapping (still **not equivalent** to a native vault; treat as low‑assurance). ([GitHub][1])

> The plugin’s README explains current platform backends, web constraints (HTTPS only), and Linux/Windows prerequisites. Keep it bookmarked. ([GitHub][1])

---

## 3) App‑level design: **Secret vault + public profile** (separation of concerns)

**Never** put secrets in your relational DB (Drift) or plain preferences. Instead:

* **Public profile (DB)**: provider id, display name, base URLs (no creds), logos, settings.
* **Secret vault (secure storage)**: per‑provider secret bundle, e.g.:

  * `secret:provider:<id>` → JSON: `{ "kind":"xtream", "username":"…", "password":"…", "createdAt":… }`
  * `secret:provider:<id>:token` for Stalker tokens.
* DB rows reference vault keys by **id**, not by copying secrets. If the DB is exported, secrets don’t ride along.

> Use Drift only for non‑sensitive data; if you ever must protect app data at rest (e.g., cached EPG), use **SQLCipher** with a key stored in secure storage. Drift documents SQLCipher integration. ([Drift][5])

---

## 4) iOS/macOS Keychain: set **accessibility** (and optionally biometrics)

* Default accessibility is **WhenUnlocked** (readable only when device is unlocked). That’s a strong default; prefer **WhenUnlockedThisDeviceOnly** to prevent migration to a new device via backups. ([Apple Developer][6])
* For **biometric gating** when reading a secret, attach an **Access Control** flag like **`userPresence`** or **`biometryCurrentSet`** (stronger, invalidates on biometric changes). Use via `SecAccessControlCreateWithFlags`. The Apple docs outline flags and behavior. ([Apple Developer][7])
* `flutter_secure_storage` exposes iOS options (`IOSOptions`) to set accessibility; the repo shows examples. ([Dart packages][8])

---

## 5) Android: Keystore/ESP choices and backup policy

* Android Keystore makes keys **non‑exportable** and can require recent user auth for key use. ([Android Developers][9])
* **Disable cloud/device backups of secrets**: Set `android:allowBackup="false"` or exclude the secure prefs file from backup rules to avoid cross‑device restore issues and key unwrap failures. Android docs cover Auto Backup configuration; code‑quality guides recommend disabling backup for apps with sensitive data. ([Android Developers][10])
* If you do allow backups for non‑secret data, **exclude** FlutterSecureStorage files explicitly. The plugin README discusses this and links to Android docs. ([GitHub][1])

---

## 6) Web (PWA) reality check

* Browser **LocalStorage persists** and is accessible to any JS running in the origin; it’s not a secure enclave. Prefer **session‑only tokens** or re‑auth flows; if you must persist, encrypt with WebCrypto and apply strict **HTTPS + HSTS**. MDN explains LocalStorage and security headers. ([MDN Web Docs][11])
* Consider **not supporting “remember password” on web** for IPTV provider creds—only store a short‑lived token in memory and require re‑entry on reload.

---

## 7) Handling provider specifics

* **Xtream**: Store `username`, `password` in vault; **store server host/port without creds** in DB. Build URLs at request time. Never log full URLs.
* **Stalker/Ministra**: Store **token** as secret and MAC (non‑secret) in DB. Refresh tokens and **atomically** replace the vault entry.
* **M3U/XMLTV**: If the playlist URL contains `u=…&p=…` or a bearer token, split secret parts into vault; keep a **template URL with placeholders** in DB (e.g., `.../get.php?username={u}&password={p}&type=m3u_plus`). Build it in memory only.

---

## 8) Biometric / passcode gating (optional but recommended)

* Gate **read access** to secrets behind biometrics using **`local_auth`**; on iOS you can enforce this at Keychain level via Access Control, on Android via Keystore key policies (user authentication required). ([Dart packages][12])
* UX: “Unlock provider credentials” prompt when user taps “Show” or “Export with secrets”.

---

## 9) Don’ts (risk hotspots)

* Don’t log secrets or secret‑bearing URLs (your logging stack should redact `Authorization`, `password`, `token`, etc.).
* Don’t store secrets in Drift, SharedPreferences, files, or LocalStorage (web) without strong mitigations. OWASP Mobile & Password Storage cheat sheets cover this. ([OWASP Cheat Sheet Series][13])
* Don’t keep secrets on the clipboard; if you must, set a **short clipboard TTL** and warn the user.

---

## 10) Key rotation, export, and recovery

* **Rotation**: design the vault so a secret can be replaced without touching the DB. Keep timestamps (`createdAt`, `rotatedAt`).
* **Export**: default to **sanitized exports** (no secrets). If you offer “export with secrets,” encrypt the bundle with a passphrase (derive a key with **Argon2id or PBKDF2** in `package:cryptography`) and write a small header with algorithm + salt + iterations. NIST guidance and OWASP cheat sheets provide KDF pointers. ([NIST Publications][14])
* **Recovery**: because some vaults don’t migrate across devices (e.g., iOS `ThisDeviceOnly`, Android Keystore keys), expect users to **re‑enter** credentials on a new device—that’s a feature, not a bug.

---

## 11) Reference implementation (clean DI, no leaks)

### 11.1 Interface + model

```dart
/// What we store in the OS vault (small JSON blobs).
sealed class ProviderSecret {
  const ProviderSecret();
  Map<String, Object?> toJson();
}

class XtreamSecret extends ProviderSecret {
  final String username;
  final String password; // or token if server supports it
  const XtreamSecret({required this.username, required this.password});
  @override Map<String, Object?> toJson() => {'kind':'xtream','u':username,'p':password};
}

class StalkerSecret extends ProviderSecret {
  final String token; // short-lived
  const StalkerSecret(this.token);
  @override Map<String, Object?> toJson() => {'kind':'stalker','token':token};
}

class M3uSecret extends ProviderSecret {
  final String? username; final String? password; final String? bearer;
  const M3uSecret({this.username, this.password, this.bearer});
  @override Map<String, Object?> toJson() => {'kind':'m3u','u':username,'p':password,'bearer':bearer};
}

abstract class SecretsVault {
  Future<void> save(String providerId, ProviderSecret secret);
  Future<ProviderSecret?> read(String providerId);
  Future<void> delete(String providerId);
}
```

### 11.2 `flutter_secure_storage` backend

```dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageVault implements SecretsVault {
  final FlutterSecureStorage _s;

  SecureStorageVault._(this._s);

  static Future<SecureStorageVault> create() async {
    // iOS/macOS: prefer WhenUnlockedThisDeviceOnly; Android: use EncryptedSharedPreferences
    final storage = FlutterSecureStorage(
      iOptions: const IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
      aOptions: const AndroidOptions(encryptedSharedPreferences: true, resetOnError: true),
      mOptions: const MacOsOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
      // WebOptions are available, but treat as low assurance.
    );
    return SecureStorageVault._(storage);
  }

  @override
  Future<void> save(String providerId, ProviderSecret secret) async {
    final key = 'secret:provider:$providerId';
    await _s.write(key: key, value: jsonEncode(secret.toJson()));
  }

  @override
  Future<ProviderSecret?> read(String providerId) async {
    final key = 'secret:provider:$providerId';
    final raw = await _s.read(key: key);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    switch (map['kind']) {
      case 'xtream': return XtreamSecret(username: map['u'], password: map['p']);
      case 'stalker': return StalkerSecret(map['token']);
      case 'm3u': return M3uSecret(username: map['u'], password: map['p'], bearer: map['bearer']);
      default: return null;
    }
  }

  @override
  Future<void> delete(String providerId) => _s.delete(key: 'secret:provider:$providerId');
}
```

**Why this design**

* Small, **key–value** secrets → perfect for Keychain/Keystore. Apple and Android docs recommend vaults for “small bits of secret data”. ([Apple Developer][2])
* Platform options chosen for **limited accessibility** and modern Android storage. ([Dart packages][15])

> If you require **biometric gating** to read, prompt with `local_auth` **before** calling `read()` and/or configure iOS Access Control flags (and Android Keystore policies) in platform code. ([Dart packages][12])

---

## 12) Building secret‑bearing URLs **only in memory**

When you need an Xtream playlist URL:

```dart
Uri buildXtreamM3uUrl({
  required Uri server,  // stored without creds in DB, e.g. https://host:port
  required XtreamSecret secret, // from vault
  String type = 'm3u_plus',
  String output = 'ts',
}) {
  return server.replace(
    path: '/get.php',
    queryParameters: {
      'username': secret.username,
      'password': secret.password,
      'type': type,
      'output': output,
    },
  );
}
```

* Keep this URL **out of logs**. Your logging layer should redact sensitive query params. (Redaction is covered in your logging blueprint.)
* Don’t cache the final URL on disk.

---

## 13) DB encryption (only if you store sensitive payloads)

If you ever cache sensitive EPG/content locally, encrypt the DB:

* Include `sqlcipher_flutter_libs`, open Drift with a **key**, then keep that key in secure storage (separate from the DB). The Drift docs show the exact setup. ([Dart packages][16])

---

## 14) Backup & migration policy

* **Android**: either **disable Auto Backup** or carefully exclude the secure prefs files, per Android’s backup docs (recommended: disable for apps handling secrets). ([Android Developers][10])
* **iOS/macOS**: prefer `…ThisDeviceOnly` accessibility to prevent migration; otherwise **Keychain items can migrate via encrypted backup**. Apple’s guidance explains accessibility trade‑offs. ([Apple Developer][6])
* **Windows/Linux**: OS vault entries are **per user profile**; don’t assume they’ll migrate across machines. MS and freedesktop docs cover the vault mechanics. ([Microsoft Learn][3])

---

## 15) Testing & hardening checklist

1. **Unit**: ensure secrets never appear in logs (assert redaction); ensure URL builder never returns a pre‑filled string without going through a secrets read.
2. **Widget**: “Show password” and “Export (with secrets)” require biometric (where supported).
3. **Integration**: rotate tokens (Stalker), rotate passwords (Xtream) → old entries are deleted from vault.
4. **On Android**: verify that reinstall from cloud backup **doesn’t** resurrect old secrets (with `allowBackup=false`). ([Android Developers][10])
5. **On iOS**: test Keychain accessibility by trying to read when locked vs unlocked (WhenUnlocked / FirstUnlock). Apple docs describe the classes. ([Apple Developer][17])
6. **Web**: ensure no persistence unless explicitly allowed; if you must, test HSTS and HTTPS requirements. ([GitHub][1])

---

## 16) Small UX policies that save you later

* “Remember me” is **opt‑in** per provider. Default: **off**.
* To view a secret, show only the last few characters by default; require biometric to reveal fully.
* “Export configuration” defaults to **sanitized** (no secrets). “Export with secrets (encrypted)” is behind extra confirmation and passphrase (Argon2id/PBKDF2). ([Dart packages][18])

---

## 17) References & further reading

* **flutter_secure_storage** (platform backends; web notes; options). ([GitHub][1])
* **Android Keystore** overview. ([Android Developers][9])
* **Apple Keychain Services** & accessibility/Access Control flags. ([Apple Developer][2])
* **Linux Secret Service / libsecret**. ([specifications.freedesktop.org][19])
* **Windows Credential Manager / DPAPI**. ([Microsoft Learn][3])
* **Drift + SQLCipher encryption**. ([Drift][5])
* **MDN LocalStorage** (web caution). ([MDN Web Docs][11])
* **OWASP Mobile & Password Storage** cheat sheets (no secrets in logs/plaintext). ([OWASP Cheat Sheet Series][13])

---

### Bottom line

* Use **OS secure storage** for all secrets, with **ThisDeviceOnly / WhenUnlocked** on Apple platforms and **Keystore‑backed** storage on Android.
* Keep provider profiles in DB, but secrets only in the **vault**.
* Build secret‑bearing URLs **in memory** right before network calls.
* Offer **biometric gating** and **sanitized exports** by default.
* Plan for **no backup of secrets** and for **re‑entry on device change**.


[1]: https://github.com/juliansteenbakker/flutter_secure_storage "GitHub - juliansteenbakker/flutter_secure_storage: A Flutter plugin for securely storing sensitive data using encrypted storage."
[2]: https://developer.apple.com/documentation/security/keychain-services?utm_source=chatgpt.com "Keychain services | Apple Developer Documentation"
[3]: https://learn.microsoft.com/en-us/windows/win32/secauthn/credentials-management?utm_source=chatgpt.com "Credentials Management - Win32 apps | Microsoft Learn"
[4]: https://github.com/GNOME/libsecret/blob/main/README.md?utm_source=chatgpt.com "libsecret/README.md at main · GNOME/libsecret · GitHub"
[5]: https://drift.simonbinder.eu/platforms/encryption/?utm_source=chatgpt.com "Encryption - Simon Binder"
[6]: https://developer.apple.com/documentation/security/ksecattraccessiblewhenunlocked?utm_source=chatgpt.com "kSecAttrAccessibleWhenUnlocked | Apple Developer Documentation"
[7]: https://developer.apple.com/documentation/security/ksecattraccesscontrol?utm_source=chatgpt.com "kSecAttrAccessControl | Apple Developer Documentation"
[8]: https://pub.dev/documentation/flutter_secure_storage/latest/flutter_secure_storage/IOSOptions-class.html?utm_source=chatgpt.com "IOSOptions class - flutter_secure_storage library - Dart API - Pub"
[9]: https://developer.android.com/privacy-and-security/keystore?utm_source=chatgpt.com "Android Keystore system | Security | Android Developers"
[10]: https://developer.android.com/identity/data/autobackup?utm_source=chatgpt.com "Back up user data with Auto Backup - Android Developers"
[11]: https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage?utm_source=chatgpt.com "Window: localStorage property - Web APIs | MDN - MDN Web Docs"
[12]: https://pub.dev/packages/local_auth?utm_source=chatgpt.com "local_auth | Flutter package - Pub"
[13]: https://cheatsheetseries.owasp.org/cheatsheets/Mobile_Application_Security_Cheat_Sheet.html?utm_source=chatgpt.com "Mobile Application Security - OWASP Cheat Sheet Series"
[14]: https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-132.pdf?utm_source=chatgpt.com "Recommendation for Password-Based Key Derivation - NIST"
[15]: https://pub.dev/documentation/flutter_secure_storage/latest/?utm_source=chatgpt.com "flutter_secure_storage - Dart API docs - Pub"
[16]: https://pub.dev/packages/sqlcipher_flutter_libs?utm_source=chatgpt.com "sqlcipher_flutter_libs | Flutter package - Pub"
[17]: https://developer.apple.com/documentation/security/ksecattraccessible?utm_source=chatgpt.com "kSecAttrAccessible | Apple Developer Documentation"
[18]: https://pub.dev/documentation/dargon2_flutter/latest/?utm_source=chatgpt.com "dargon2_flutter - Dart API docs - Pub"
[19]: https://specifications.freedesktop.org/secret-service-spec/latest/description.html?utm_source=chatgpt.com "API Documentation | Secret Service API Draft - freedesktop.org"
