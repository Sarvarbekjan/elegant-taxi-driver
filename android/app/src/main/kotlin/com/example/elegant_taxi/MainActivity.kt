package com.example.elegant_taxi

import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import androidx.annotation.NonNull
import com.yandex.mapkit.MapKitFactory
import com.yandex.runtime.i18n.I18nManagerFactory
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.PI
import kotlin.math.exp
import kotlin.math.sin

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.elegant_taxi/native"
    private val PREFS_NAME = "ElegantDriverPrefs"
    private val DATA_KEY = "saved_driver_data"

    @Volatile
    private var isRingingOrder = false
    private var ringThread: Thread? = null
    private var currentAudioTrack: AudioTrack? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        try {
            MapKitFactory.setApiKey("YANDEX_API_KEY_SHU_YERGA")
        } catch (e: Exception) {}
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveData" -> {
                    val data = call.argument<String>("data") ?: ""
                    val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    prefs.edit().putString(DATA_KEY, data).apply()
                    result.success(true)
                }
                "loadData" -> {
                    val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    val saved = prefs.getString(DATA_KEY, "") ?: ""
                    result.success(saved)
                }
                "setMapLocale" -> {
                    try {
                        val locale = call.argument<String>("locale") ?: "ru_RU"
                        I18nManagerFactory.setLocale(locale)
                    } catch (e: Exception) {}
                    result.success(true)
                }
                "playOrderRingtone" -> {
                    startTaxiOrderRingtone()
                    result.success(true)
                }
                "stopOrderRingtone" -> {
                    stopTaxiOrderRingtone()
                    result.success(true)
                }
                "playSound" -> {
                    playShortBeep()
                    result.success(true)
                }
                "dialPhone" -> {
                    try {
                        val phone = call.argument<String>("phone") ?: ""
                        if (phone.isNotEmpty()) {
                            val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:$phone"))
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                        }
                    } catch (e: Exception) {}
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    // Mashhur Taksi Zakaz Radar Ringtoni (Yandex Pro / Taksometr uslubidagi baland ohang)
    private fun startTaxiOrderRingtone() {
        if (isRingingOrder) return
        isRingingOrder = true

        ringThread = Thread {
            val sampleRate = 44100
            // Taksi zakaz ohangi notalari (Hz) va davomiyligi (ms)
            val notes = doubleArrayOf(659.25, 830.61, 987.77, 1318.51, 987.77, 1318.51)
            val durationsMs = intArrayOf(110, 110, 110, 220, 110, 320)

            var totalSamples = 0
            for (d in durationsMs) {
                totalSamples += (sampleRate * d) / 1000
            }
            val pauseSamples = (sampleRate * 350) / 1000
            val patternSamples = totalSamples + pauseSamples
            val buffer = ShortArray(patternSamples)

            var offset = 0
            for (i in notes.indices) {
                val freq = notes[i]
                val count = (sampleRate * durationsMs[i]) / 1000
                for (s in 0 until count) {
                    val t = s.toDouble() / sampleRate
                    val env = exp(-3.2 * t)
                    // Asosiy ohang + 2-chi va 3-chi garmonika (jarangdor taksometr qo'ng'irog'i)
                    val wave = (0.65 * sin(2.0 * PI * freq * t) +
                            0.25 * sin(2.0 * PI * freq * 2.0 * t) +
                            0.10 * sin(2.0 * PI * freq * 3.0 * t)) * env
                    buffer[offset + s] = (wave * 31000).toInt().coerceIn(-32767, 32767).toShort()
                }
                offset += count
            }

            var loops = 0
            while (isRingingOrder && loops < 16) {
                try {
                    triggerVibration(450)
                    val track = AudioTrack.Builder()
                        .setAudioAttributes(
                            AudioAttributes.Builder()
                                .setUsage(AudioAttributes.USAGE_ALARM)
                                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                .build()
                        )
                        .setAudioFormat(
                            AudioFormat.Builder()
                                .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                                .setSampleRate(sampleRate)
                                .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                                .build()
                        )
                        .setBufferSizeInBytes(buffer.size * 2)
                        .setTransferMode(AudioTrack.MODE_STATIC)
                        .build()

                    currentAudioTrack = track
                    track.write(buffer, 0, buffer.size)
                    track.play()

                    var waited = 0
                    while (isRingingOrder && waited < 1350) {
                        Thread.sleep(50)
                        waited += 50
                    }
                    track.stop()
                    track.release()
                } catch (e: Exception) {
                    try {
                        val notification: Uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                        val r = RingtoneManager.getRingtone(applicationContext, notification)
                        r.play()
                        Thread.sleep(1500)
                        r.stop()
                    } catch (_: Exception) {}
                }
                loops++
            }
            isRingingOrder = false
        }
        ringThread?.start()
    }

    private fun stopTaxiOrderRingtone() {
        isRingingOrder = false
        try {
            currentAudioTrack?.stop()
            currentAudioTrack?.release()
            currentAudioTrack = null
        } catch (e: Exception) {}
    }

    private fun playShortBeep() {
        Thread {
            try {
                triggerVibration(180)
                val sampleRate = 44100
                val count = (sampleRate * 180) / 1000
                val buf = ShortArray(count)
                for (s in 0 until count) {
                    val t = s.toDouble() / sampleRate
                    val wave = sin(2.0 * PI * 880.0 * t) * exp(-6.0 * t)
                    buf[s] = (wave * 28000).toInt().toShort()
                }
                val track = AudioTrack(
                    AudioManager.STREAM_NOTIFICATION,
                    sampleRate,
                    AudioFormat.CHANNEL_OUT_MONO,
                    AudioFormat.ENCODING_PCM_16BIT,
                    buf.size * 2,
                    AudioTrack.MODE_STATIC
                )
                track.write(buf, 0, buf.size)
                track.play()
                Thread.sleep(220)
                track.release()
            } catch (e: Exception) {}
        }.start()
    }

    private fun triggerVibration(durationMs: Long) {
        try {
            val v = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                v.vibrate(VibrationEffect.createOneShot(durationMs, VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION")
                v.vibrate(durationMs)
            }
        } catch (e: Exception) {}
    }

    override fun onDestroy() {
        stopTaxiOrderRingtone()
        super.onDestroy()
    }
}
