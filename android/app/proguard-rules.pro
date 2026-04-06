# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Pertahankan Signature untuk Generic Types (Penting untuk Gson/deserialization)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

# Jika kamu menggunakan Gson secara langsung
-keep class com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.TypeVariable
