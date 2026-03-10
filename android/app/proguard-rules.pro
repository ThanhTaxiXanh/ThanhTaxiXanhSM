# Proguard rules cho Thanh Taxi Xanh SM

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Drift / SQLite
-keep class com.example.thanh_taxi_xanh_sm.** { *; }
-dontwarn org.sqlite.**

# flutter_secure_storage
-keep class androidx.security.crypto.** { *; }

# local_auth / Biometrics
-keep class androidx.biometric.** { *; }

# Google APIs
-keep class com.google.api.** { *; }
-keep class com.google.auth.** { *; }
-dontwarn com.google.api.**

# Gson / JSON
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
