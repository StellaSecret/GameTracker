# Flutter, Google Sign-In, Play Services et Firebase ont été retirés d'ici :
# ces SDK embarquent déjà leurs propres consumer-rules.pro (appliquées
# automatiquement depuis leur AAR) et annotent leurs API sensibles à la
# réflexion avec @Keep, qui est honoré par la config ProGuard par défaut
# d'Android. Les garder ici en plus avec `-keep class X.** { *; }` ne fait
# que geler tout ce code (io.flutter.**, com.google.android.gms.**,
# com.google.api.**, com.google.firebase.**) — pas de renommage, pas de
# suppression, pas d'inlining — ce qui explique le seuil "Optimisation du
# code DEX" trop bas dans Play Console (ces packages représentent une
# grosse partie du DEX). Si un crash par réflexion réapparaît après ce
# changement, ajoutez une règle -keep CIBLÉE sur la classe précise, pas un
# `**` général.

# Flutter Play Store Split Application — classes manquantes R8
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-dontwarn io.flutter.app.FlutterPlayStoreSplitApplication
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# RevenueCat — gardé : le SDK désérialise les résultats d'achat par
# réflexion et sa doc officielle recommande ce keep.
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
