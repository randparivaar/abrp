# Flutter Rules & Deferred Components
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn com.google.android.play.core.**

# WorkManager & Room (Prevents WorkDatabase crash on app startup)
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.** { *; }
-keep class androidx.work.** { *; }
-keepclassmembers class androidx.work.** { *; }
-dontwarn androidx.work.**
-dontwarn androidx.room.**

# Google Mobile Ads (AdMob)
-keep public class com.google.android.gms.ads.** {
   public *;
}
-keep public class com.google.ads.** {
   public *;
}
-keep class com.google.android.gms.internal.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

