package com.akule.visionscreen

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val channel = "com.visionscreen/ambient_light"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val sensorManager = getSystemService(SENSOR_SERVICE) as SensorManager
        val lightSensor = sensorManager.getDefaultSensor(Sensor.TYPE_LIGHT)

        Log.d("AmbientLight", "Light sensor available: ${lightSensor != null}")

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setStreamHandler(object : EventChannel.StreamHandler {
                private var listener: SensorEventListener? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    Log.d("AmbientLight", "onListen called")
                    if (lightSensor == null) {
                        Log.d("AmbientLight", "No light sensor, ending stream")
                        events.endOfStream()
                        return
                    }
                    listener = object : SensorEventListener {
                        override fun onSensorChanged(event: SensorEvent) {
                            val lux = event.values[0].toDouble()
                            Log.d("AmbientLight", "Lux reading: $lux")
                            events.success(lux)
                        }
                        override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}
                    }
                    sensorManager.registerListener(
                        listener, lightSensor, SensorManager.SENSOR_DELAY_NORMAL
                    )
                }

                override fun onCancel(arguments: Any?) {
                    Log.d("AmbientLight", "onCancel called")
                    listener?.let { sensorManager.unregisterListener(it) }
                    listener = null
                }
            })
    }
}
