package com.example.visionscreen

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {

    private val LIGHT_CHANNEL = "visionscreen/light"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
                    sensorManager?.registerListener(
                        listener,
                        lightSensor,
                        SensorManager.SENSOR_DELAY_NORMAL
                    )
                }

                override fun onCancel(arguments: Any?) {
                    sensorManager?.unregisterListener(listener)
                    listener = null
                    sensorManager = null
                }
            })
    }
}
