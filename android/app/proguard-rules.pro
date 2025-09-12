# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# Camera Plugin
-keep class io.flutter.plugins.camera.** { *; }

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Google ML Kit (pour les codes-barres si utilisé)
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }

# Mobile Scanner (codes-barres)
-keep class dev.steenbakker.mobile_scanner.** { *; }
-keep class com.google.zxing.** { *; }

# ZXing (codes-barres)
-dontwarn com.google.zxing.**
-keep class com.google.zxing.** { *; }

# Supabase / HTTP
-keep class io.supabase.** { *; }
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }