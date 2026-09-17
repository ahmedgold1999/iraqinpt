# Ignore missing play core classes for deferred components in Flutter
-dontwarn com.google.android.play.core.**

# Flutter Wrapper ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class io.flutter.plugin.editing.** { *; }
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.header.** { *; }
-keep class io.flutter.useragent.** { *; }

# Firebase & Firestore rules
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-dontwarn com.google.crypto.tink.**
-dontwarn javax.annotation.**

# Kotlin rules
-keep class kotlin.** { *; }
-keep interface kotlin.** { *; }
-dontwarn kotlin.**
