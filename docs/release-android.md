# Android Release Guide

This document describes how PekSoft Radio Browser is identified, versioned, signed, and packaged as an Android App Bundle (`.aab`) for Google Play distribution.

## 1. Application ID

The Android application ID is configured in `apps/mobile/android/app/build.gradle.kts`:

```kotlin
defaultConfig {
    applicationId = "com.peksoft.radio"
    minSdk = flutter.minSdkVersion
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
}
```

- **`applicationId` (`com.peksoft.radio`)** is the permanent package identifier on Google Play and on user devices. Once published, it cannot be changed without creating a separate Play Store listing.
- **`namespace` (`com.peksoft.peksoft_radio`)** is the Kotlin/R-class namespace used internally at compile time and does not affect the Play Store identity.

## 2. Version Numbering

Versions are defined in `apps/mobile/pubspec.yaml`:

```yaml
version: 1.0.0+1
```

Flutter maps this single line into Android Gradle properties:

- **Semantic version (`1.0.0`)** -> `flutter.versionName` (shown to users in Google Play and Android App Info).
- **Build number (`1`)** -> `flutter.versionCode` (strictly increasing integer required by Google Play on every upload).

For CI or release builds, you can either bump `version:` in `pubspec.yaml` or override at build time:

```bash
flutter build appbundle --release --build-name=1.0.1 --build-number=2
```

## 3. Signing & Play App Signing

Google Play uses **Play App Signing**, which separates the **App Signing Key** from the **Upload Key**:

1. **App Signing Key** (held by Google Play): Google signs the final split APKs delivered to user devices. Even if your upload key is lost or rotated, your app's signing identity on user devices remains intact.
2. **Upload Key** (held by the developer / CI): You sign the `.aab` locally or in CI with an upload keystore before uploading to Play Console.

### Generating an Upload Keystore

Run `keytool` (from the JDK bundled with Android Studio) outside the repository:

```bash
keytool -genkey -v -keystore ~/peksoft-radio-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Never commit `.jks`, `.keystore`, or `key.properties` files to Git.

### Configuring `key.properties` for Production Signing

Create `apps/mobile/android/key.properties` (gitignored):

```properties
storePassword=<keystore-password>
keyPassword=<key-password>
keyAlias=upload
storeFile=/absolute/path/to/peksoft-radio-upload.jks
```

In Phase 3, `apps/mobile/android/app/build.gradle.kts` keeps `signingConfig = signingConfigs.getByName("debug")` in `buildTypes.release` so release bundle builds can be verified locally without committing secrets. Before uploading to Google Play Console, update `build.gradle.kts` to load `key.properties` into a `release` signing config.

## 4. Producing a Release App Bundle

From `apps/mobile`:

```bash
flutter build appbundle --release
```

Flutter compiles AOT ARM/x86_64 binaries, applies R8 shrinking/obfuscation, and writes the bundle to:

```text
apps/mobile/build/app/outputs/bundle/release/app-release.aab
```

### Verifying the Bundle Locally

You can inspect or test the `.aab` on a connected device before uploading using `bundletool`:

```bash
bundletool build-apks --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=build/app/outputs/bundle/release/app-release.apks
bundletool install-apks --apks=build/app/outputs/bundle/release/app-release.apks
```
