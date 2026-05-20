package com.example.visionscreen

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "com.visionscreen/ambient_light"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val sensorManager = getSystemService(SENSOR_SERVICE) as SensorManager
        val lightSensor = sensorManager.getDefaultSensor(Sensor.TYPE_LIGHT)
        val handler = Handler(Looper.getMainLooper())

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                if (call.method != "getLux") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (lightSensor == null) {
                    result.success(null)
                    return@setMethodCallHandler
                }

                var settled = false

                val listener = object : SensorEventListener {
                    override fun onSensorChanged(event: SensorEvent) {
                        if (settled) return
                        settled = true
                        sensorManager.unregisterListener(this)
                        result.success(event.values[0].toDouble())
                    }
                    override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}
                }

                sensorManager.registerListener(
                    listener, lightSensor, SensorManager.SENSOR_DELAY_NORMAL
                )

                // Timeout after 10 s in case the sensor never fires
                handler.postDelayed({
                    if (settled) return@postDelayed
                    settled = true
                    sensorManager.unregisterListener(listener)
                    result.success(null)
                }, 10000)
            }
    }
}
