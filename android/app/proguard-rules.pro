# Flutter specific
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep the MainActivity
-keep class com.akule.visionscreen.MainActivity { *; }

# Keep model classes used by JSON/Serialization
-keep class com.akule.visionscreen.** { *; }

# Google ML Kit
-keep class com.google.mlkit.** { *; }

# Keep EventChannel, MethodChannel, BasicMessageChannel
-keep class io.flutter.plugin.common.** { *; }
