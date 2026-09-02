-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.* { *; }
-keep class com.google.android.libraries.barhopper.* { *; }
-keep class com.google.photos.* { *; }

-keepclassmembers class * extends java.lang.Enum {
    <fields>;
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
