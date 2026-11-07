package pl.mc.jureczek

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Przekazuje do Fluttera tekst udostępniony z innej aplikacji (np. Google Maps)
/// i stuka wibracją na jego prośbę.
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null

    /// Udostępnienie, z którym uruchomiono aplikację; Flutter odbiera je raz.
    private var initialShare: Map<String, String?>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initialShare = sharedText(intent)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialShare" -> {
                        result.success(initialShare)
                        initialShare = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SPLASH_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "nextSceneTurn" -> result.success(nextSceneTurn())
                    else -> result.notImplemented()
                }
            }
        // HapticFeedback z Fluttera milczy, gdy wibracje dotykowe w systemie są wyłączone.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HAPTICS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "tap" -> {
                        tap()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /// Numer tego uruchomienia; ekran powitalny bierze z niego kolejną scenę.
    private fun nextSceneTurn(): Int {
        val prefs = getSharedPreferences(SPLASH_PREFS, Context.MODE_PRIVATE)
        val turn = prefs.getInt(SCENE_TURN, 0)
        prefs.edit().putInt(SCENE_TURN, turn + 1).apply()
        return turn
    }

    private fun tap() {
        val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator ?: return
        if (!vibrator.hasVibrator()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(TAP_MS, VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(TAP_MS)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        sharedText(intent)?.let { channel?.invokeMethod("onShare", it) }
    }

    private fun sharedText(intent: Intent?): Map<String, String?>? {
        if (intent?.action != Intent.ACTION_SEND || intent.type != "text/plain") return null
        val text = intent.getStringExtra(Intent.EXTRA_TEXT) ?: return null
        return mapOf("text" to text, "subject" to intent.getStringExtra(Intent.EXTRA_SUBJECT))
    }

    private companion object {
        const val CHANNEL = "pl.mc.jureczek/share"
        const val HAPTICS_CHANNEL = "pl.mc.jureczek/haptics"
        const val SPLASH_CHANNEL = "pl.mc.jureczek/splash"
        const val SPLASH_PREFS = "splash"
        const val SCENE_TURN = "scene_turn"
        const val TAP_MS = 40L
    }
}
