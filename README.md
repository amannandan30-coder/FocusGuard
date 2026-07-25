# FocusGuard

FocusGuard is an Android digital-wellbeing companion. It uses supported Android APIs only and never modifies, injects into, or reverse engineers another app.

## Phase 1: setup and authentication

This phase provides a Material 3 Flutter app with light/dark themes, clean feature-first structure, Firebase Authentication, Firestore user profiles, Google Sign-In, password reset, sign-out, and a guarded authenticated shell.

### Prerequisites

1. Install the current [Flutter stable SDK](https://docs.flutter.dev/get-started/install/windows/mobile) and Android Studio.
2. Create a Firebase project and enable **Email/Password** and **Google** in Firebase Authentication.
3. Create a Firestore database in production mode and add the rules below.
4. From this directory, run `flutterfire configure --platforms=android,web,windows` to generate `lib/firebase_options.dart` and add `android/app/google-services.json`.
5. Run `flutter pub get`, then `flutter run`.

Until Step 4 is complete, the app displays a configuration screen instead of
crashing with `FirebaseOptions cannot be null`.

### Firebase project selection

Firebase credentials are not present in this repository. After signing in to
Firebase, run the following command with your own Firebase project ID. It
replaces the safe placeholder in `lib/firebase_options.dart` with the real
options for Android, Web, and Windows:

```powershell
$env:PATH += ';C:\Users\amann\AppData\Local\Pub\Cache\bin'
flutterfire configure --project YOUR_FIREBASE_PROJECT_ID --platforms=android,web,windows --yes
```

Do not use another Firebase project's options: the Android app registered in
Firebase must use package ID `com.focusguard.app`.

### OneDrive build-cache workaround

Source files remain in OneDrive, but the repository's `build` folder is a
Windows junction to `C:\Users\amann\AppData\Local\FocusGuard\build`.
Flutter therefore writes generated artifacts outside OneDrive, preventing sync
locks. Do not replace the `build` junction with a regular folder.

### Android setup after `flutter create .`

Android and Windows project files are included. The Android package ID is
`com.focusguard.app`, which must be the Android app ID selected in Firebase.
The app requires Android API 23 or newer.

### Platform verification

- **Web:** add `localhost` and your deployed domain under Firebase Authentication
  → Settings → Authorized domains, then run `flutter build web`.
- **Android:** install Android Studio's Android SDK, set `ANDROID_HOME` to its
  SDK path, and add the Android app with package ID `com.focusguard.app` in
  Firebase. Add SHA-1/SHA-256 fingerprints before using Google Sign-In.
- **Windows:** enable Windows **Developer Mode** before `flutter build windows`;
  Flutter plugins require symlink support. Configure Firebase with the Windows
  platform only if the Firebase products you use support the desktop target.

### Firestore rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, create, update: if request.auth != null && request.auth.uid == userId;
      allow delete: if false;
    }
  }
}
```

### Architecture

`features/auth` follows domain → data → presentation. Presentation talks to Riverpod providers, providers depend on the repository abstraction, and only the Firebase data source knows Firebase SDK details. Future wellbeing monitoring should become a separate feature with an Android platform channel; it must use Usage Stats/Accessibility APIs and display only FocusGuard-owned UI.
