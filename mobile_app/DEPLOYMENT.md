# Mobile App Deployment & Publishing Guide (Android)

This document provides step-by-step instructions for building, signing, and publishing the **Akhil Bhartiya Rander Parivar Samaj** Flutter mobile application (`mobile_app`) to the Google Play Store.

---

## 📱 General Information

* **Package Name / Application ID**: `com.abrp.community`
* **Framework**: Flutter (Dart)
* **Production API Base URL**: `https://abrp.vercel.app/api/v1`
* **Keystore Location**: `android/app/upload-keystore.jks`
* **Key Properties**: `android/key.properties`

---

## 🔑 1. Keystore & Signing Setup

The Android release build requires a signed release key configured in `android/key.properties` and `android/app/build.gradle.kts`.

### Check Configuration
Ensure `android/key.properties` exists with the following structure:

```properties
storePassword=<YOUR_STORE_PASSWORD>
keyPassword=<YOUR_KEY_PASSWORD>
keyAlias=upload
storeFile=upload-keystore.jks
```

> [!IMPORTANT]
> Keep `upload-keystore.jks` and `key.properties` safe and backed up (see `play_store_signing_backup/README_CREDENTIALS.txt` for your actual credentials). Never commit the actual passwords to Git.

---

## 📦 2. Versioning

Before building a release, update the version number in `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

* `1.0.0` is the **Version Name** (displayed to users).
* `+1` is the **Version Code** (must increment for every submission to Google Play).

---

## 🛠️ 3. Building Release Artifacts

### Option A: Build Android App Bundle (.aab) – *Required for Google Play Store*

Run from the `mobile_app` directory:

```bash
flutter build appbundle --release --dart-define=BASE_URL="https://abrp.vercel.app/api/v1"
```

* **Output Location**: `mobile_app/build/app/outputs/bundle/release/app-release.aab`

---

### Option B: Build Release APK (.apk) – *For Direct Distribution / Testing*

```bash
flutter build apk --release --dart-define=BASE_URL="https://abrp.vercel.app/api/v1"
```

* **Output Location**: `mobile_app/build/app/outputs/flutter-apk/app-release.apk`

---

## 🚀 4. Publishing to Google Play Console

1. Log into the **[Google Play Console](https://play.google.com/console)**.
2. Select or create your application with package name **`com.abrp.community`**.
3. Go to **Testing** -> **Internal testing** or **Production**.
4. Click **Create new release**.
5. Upload the generated `.aab` file from `build/app/outputs/bundle/release/app-release.aab`.
6. Enter release notes and save.
7. Review and rollout the release to users!
