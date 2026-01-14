# Flutter-specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep MainActivity (entry point)
-keep class life.eucann.nist_pocket_guide.MainActivity { *; }

# Keep plugin registrant classes
-keep class * extends io.flutter.plugin.common.PluginRegistry$PluginRegistrantCallback
-keep class * extends io.flutter.embedding.engine.plugins.FlutterPlugin

# If you're using reflection/dynamic loading, uncomment:
# -keep class com.yourcompany.** { *; }

# Don't remove annotations
-keepattributes *Annotation*
