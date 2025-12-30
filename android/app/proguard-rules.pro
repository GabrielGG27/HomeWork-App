# ProGuard / R8 rules to keep classes used by flutter_local_notifications
# This prevents R8 from removing the ScheduledNotificationReceiver and
# ScheduledNotificationBootReceiver classes which are used for scheduled
# notifications and boot handling.

# Keep all classes in the flutter local notifications plugin package
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep Flutter plugin registrant classes (if any)
-keep class io.flutter.plugin.** { *; }

# Keep any BroadcastReceivers declared by the plugin
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }

# Keep any classes referenced via reflection by the plugin
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# Preserve generic signature information used by Gson's TypeToken
-keepattributes Signature

# Preserve annotations (may be referenced via reflection)
-keepattributes *Annotation*

# Keep Gson classes used for parsing to avoid R8 stripping
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**
