## Jitsi Meet SDK 11+ & React Native Bridge Rules
-keep class org.jitsi.meet.** { *; }
-keep class org.webrtc.** { *; }

## React Native Bridge Protection (Essential for Jitsi Flags)
-keep class com.facebook.react.** { *; }
-keep class com.facebook.soloader.** { *; }
-keep public class * extends com.facebook.react.bridge.JavaScriptModule { *; }
-keep public class * extends com.facebook.react.bridge.NativeModule { *; }
-keep class com.facebook.react.bridge.ReadableArray { *; }
-keep class com.facebook.react.bridge.ReadableMap { *; }
-keep class com.facebook.react.bridge.WritableArray { *; }
-keep class com.facebook.react.bridge.WritableMap { *; }
-keep class com.facebook.react.bridge.Arguments { *; }
-keep class com.facebook.react.bridge.ReactContext { *; }
-keep class com.facebook.react.bridge.ReactContextBaseJavaModule { *; }

## OkHttp & Jackson (Jitsi dependencies)
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-keep class com.fasterxml.jackson.** { *; }

## Suppression
-dontwarn com.facebook.react.**
-dontwarn org.jitsi.meet.**
-dontwarn org.webrtc.**
-dontwarn com.facebook.soloader.**
-dontwarn com.fasterxml.jackson.**

## TensorFlow Lite (Forensic Lab AI)
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**
