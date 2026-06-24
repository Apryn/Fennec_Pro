# ────────────────────────────────────────────────────────────────────────────
# Fennec Pro - ProGuard / R8 Rules
# ────────────────────────────────────────────────────────────────────────────

# Flutter engine - never strip
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# WebView & Chromium bridge
-keep class android.webkit.** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Google Fonts (loaded at runtime via network)
-keep class com.google.** { *; }
-dontwarn com.google.**

# Keep all model/data classes (prevent stripping of Map keys)
-keepclassmembers class ** {
    public *;
}

# OkHttp (used by webview_flutter internally)
-dontwarn okhttp3.**
-dontwarn okio.**

# Kotlin standard library
-dontwarn kotlin.**
-keep class kotlin.** { *; }
