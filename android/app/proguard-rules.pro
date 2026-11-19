# flutter_local_notifications 17 uses Gson TypeToken when restoring scheduled
# notifications after Android boot. R8 full mode needs both the generic
# signature and the TypeToken classes retained for reflective type recovery.
-keepattributes Signature
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
