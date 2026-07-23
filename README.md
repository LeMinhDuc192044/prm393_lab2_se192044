# prm393_lab2_se192044

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

## Firebase Authentication

The app supports Firebase Email/Password and Google sign-in.

Before testing Google sign-in on Android:

1. In Firebase Console, open the Android app
   `com.example.prm393_lab2_se192044`.
2. Add the debug signing fingerprints:
   - SHA-1: `21:5D:90:5F:FD:EF:E9:A0:0B:3C:77:46:D2:A8:CF:82:48:0C:AF:6B`
   - SHA-256:
     `7D:02:91:EC:8A:42:75:47:36:6B:D4:85:7B:8D:F8:D2:5F:F4:A4:1B:96:6F:CA:79:3E:83:27:64:86:F3:86:8E`
3. Download the updated `google-services.json` and place it at
   `android/app/google-services.json`.
4. Get the Web OAuth client ID from Firebase Authentication / Google Cloud,
   then run:

```bash
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


![CodeRabbit Pull Request Reviews](https://img.shields.io/coderabbit/prs/github/LeMinhDuc192044/prm393_lab2_se192044?utm_source=oss&utm_medium=github&utm_campaign=LeMinhDuc192044%2Fprm393_lab2_se192044&labelColor=171717&color=FF570A&link=https%3A%2F%2Fcoderabbit.ai&label=CodeRabbit+Reviews)
