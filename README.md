# حساباتي — Hisabati

تطبيق محاسبة عربي أصلي مبني بـ Flutter لنظام Android، يعمل محليًا ويستخدم SQLite.

## البناء

يتطلب Flutter stable وAndroid SDK.

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

تُنفّذ مراحل التطوير تدريجيًا، ويُبنى APK عبر GitHub Actions عند دفع تغييرات إلى المستودع.
