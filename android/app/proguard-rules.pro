# ProGuard Rules for Capacitor App

# Keep the Capacitor classes
-keep class com.getcapacitor.** { *; }
-keep class capacitor.** { *; }

# Keep the plugin classes
-keep class **.CapacitorPlugin
-keep class * implements com.getcapacitor.Plugin
-keep class com.getcapacitor.api.** { *; }

# Keep WebView and related classes
-keep class android.webkit.WebView { *; }
-keep class android.webkit.WebSettings { *; }

# Keep JavaScript interfaces
-keepattributes JavascriptInterface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep serializers and deserializers for JSON
-keep class org.json.** { *; }
-keep class com.getcapacitor.JSON** { *; }

# Keep the application class
-keep class **.MainApplication { *; }
-keep class **.MainActivity { *; }

# Don't obfuscate the names of methods called from JavaScript
-keepclassmembers class * extends com.getcapacitor.Plugin {
    public <methods>;
}

# Don't strip any annotations
-keepattributes *Annotation*

# Keep line numbers in stack traces
-keepattributes SourceFile,LineNumberTable

# Keep generic signatures
-keepattributes Signature
