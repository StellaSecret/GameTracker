# Flutter wrapper
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Play Store Split Application — classes manquantes R8
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-dontwarn io.flutter.app.FlutterPlayStoreSplitApplication
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Google Sign-In
-keep class com.google.android.gms.** { *; }
-keep class com.google.api.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }

# RevenueCat
-keep class com.revenuecat.purchases.** { *; }

# Keep native crash symbols readable
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
