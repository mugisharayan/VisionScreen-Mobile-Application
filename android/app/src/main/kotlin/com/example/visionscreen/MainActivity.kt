package com.example.visionscreen

import android.content.Context
import android.database.ContentObserver
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import java.util.Timer
import java.util.TimerTask

class MainActivity : FlutterActivity() {

    private val LIGHT_CHANNEL      = "visionscreen/light"
    private val BRIGHTNESS_CHANNEL = "visionscreen/brightness"

    private var brightnessObserver: ContentObserver? = null
    private var brightnessTimer: Timer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Ambient light sensor ──────────────────────────────────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, LIGHT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                private var sensorManager: SensorManager? = null
                private var listener: SensorEventListener? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
                    val lightSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_LIGHT)
                    if (lightSensor == null) {
                        events?.error("NO_SENSOR", "Light sensor not available", null)
                        return
                    }
                    listener = object : SensorEventListener {
                        override fun onSensorChanged(event: SensorEvent?) {
                            event?.let { events?.success(it.values[0].toDouble()) }
                        }
                        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
                    }
                    sensorManager?.registerListener(listener, lightSensor, SensorManager.SENSOR_DELAY_NORMAL)
                }

                override fun onCancel(arguments: Any?) {
                    sensorManager?.unregisterListener(listener)
                    listener = null
                    sensorManager = null
                }
            })

        // ── Screen brightness ─────────────────────────────────────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, BRIGHTNESS_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    brightnessObserver?.let { contentResolver.unregisterContentObserver(it) }
                    brightnessTimer?.cancel()

                    fun readBrightness(): Double {
                        val w = window?.attributes?.screenBrightness ?: -1f
                        if (w in 0f..1f) return w.toDouble()
                        return try {
                            Settings.System.getInt(contentResolver, Settings.System.SCREEN_BRIGHTNESS) / 255.0
                        } catch (e: Exception) { 1.0 }
                    }

                    val handler = Handler(Looper.getMainLooper())
                    brightnessObserver = object : ContentObserver(handler) {
                        override fun onChange(selfChange: Boolean) { events?.success(readBrightness()) }
                    }
                    contentResolver.registerContentObserver(
                        Settings.System.getUriFor(Settings.System.SCREEN_BRIGHTNESS),
                        false, brightnessObserver!!
                    )
                    brightnessTimer = Timer()
                    brightnessTimer?.scheduleAtFixedRate(object : TimerTask() {
                        override fun run() { runOnUiThread { events?.success(readBrightness()) } }
                    }, 0L, 300L)
                }

                override fun onCancel(arguments: Any?) {
                    brightnessObserver?.let { contentResolver.unregisterContentObserver(it) }
                    brightnessObserver = null
                    brightnessTimer?.cancel()
                    brightnessTimer = null
                }
            })
    }
}
