# Métodos chamados pelo JavaScript do app (ponte NexusAndroid)
-keepclassmembers class com.nexusworksdigital.nexustuner.NexusBridge {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
