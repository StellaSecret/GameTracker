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

# WorkManager / Room — WorkManager's WorkDatabase (a Room database) is
# built from annotation-processor-generated _Impl classes, instantiated
# via reflection at runtime. Its AAR is supposed to ship consumer
# ProGuard rules automatically, but a "Failed to create an instance of
# androidx.work.impl.WorkDatabase" crash under a minified build points at
# something stripping/renaming what those generated classes need.
-keep class androidx.work.** { *; }
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
-keepclassmembers class * extends androidx.room.RoomDatabase { *; }
-dontwarn androidx.room.paging.**

# Keep native crash symbols readable
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
