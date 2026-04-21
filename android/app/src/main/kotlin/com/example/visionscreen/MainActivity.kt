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
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetectorOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.Timer
import java.util.TimerTask
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterActivity() {

    private val LIGHT_CHANNEL      = "visionscreen/light"
    private val BRIGHTNESS_CHANNEL = "visionscreen/brightness"
    private val FRAME_CHANNEL      = "visionscreen/process_frame"

    private var brightnessObserver: ContentObserver? = null
    private var brightnessTimer: Timer? = null

    // Processing lock — prevents queuing multiple frames simultaneously
    private val isProcessing = AtomicBoolean(false)

    private val faceDetector by lazy {
        val opts = FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
            .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_NONE)
            .setClassificationMode(FaceDetectorOptions.CLASSIFICATION_MODE_NONE)
            .setMinFaceSize(0.15f)
            .build()
        FaceDetection.getClient(opts)
    }

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

        // ── Process camera frame → face distance ──────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FRAME_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "processFrame") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                // Drop frame if already processing one
                if (!isProcessing.compareAndSet(false, true)) {
                    result.success(null)
                    return@setMethodCallHandler
                }

                val bytes  = call.argument<ByteArray>("bytes")  ?: run { isProcessing.set(false); result.success(null); return@setMethodCallHandler }
                val width  = call.argument<Int>("width")        ?: run { isProcessing.set(false); result.success(null); return@setMethodCallHandler }
                val height = call.argument<Int>("height")       ?: run { isProcessing.set(false); result.success(null); return@setMethodCallHandler }

                // Front camera on Android is typically rotated 270° relative to portrait
                // This is the most common value — fixes upside-down/sideways face detection
                val rotation = 270

                val image: InputImage? = try {
                    InputImage.fromByteArray(bytes, width, height, rotation, InputImage.IMAGE_FORMAT_NV21)
                } catch (e1: Exception) {
                    try {
                        InputImage.fromByteArray(bytes, width, height, rotation, InputImage.IMAGE_FORMAT_YV12)
                    } catch (e2: Exception) {
                        null
                    }
                }

                if (image == null) {
                    isProcessing.set(false)
                    result.success(mapOf("distance" to -1.0, "status" to "no_face"))
                    return@setMethodCallHandler
                }

                faceDetector.process(image)
                    .addOnSuccessListener { faces ->
                        isProcessing.set(false)
                        if (faces.isEmpty()) {
                            result.success(mapOf("distance" to -1.0, "status" to "no_face"))
                        } else {
                            val face = faces.maxByOrNull { it.boundingBox.width() }!!
                            val faceWidthPx = face.boundingBox.width().toDouble()

                            // Focal length formula: distance = (realFaceWidth * focalPx) / faceWidthPx
                            // realFaceWidth = 14cm average
                            // focalPx ≈ imageWidth * 0.35 / 0.14 * 0.01 — calibrated so that
                            // at 40cm, face ratio ~0.35 → distance = 14 / 0.35 = 40cm
                            val ratio = faceWidthPx / width.toDouble()
                            val distanceCm = if (ratio > 0) (14.0 / ratio) else -1.0

                            val status = when {
                                distanceCm <= 0  -> "no_face"
                                distanceCm < 25  -> "too_close"
                                distanceCm < 37  -> "slightly_close"
                                distanceCm <= 43 -> "correct"
                                distanceCm <= 55 -> "slightly_far"
                                else             -> "too_far"
                            }
                            result.success(mapOf("distance" to distanceCm, "status" to status))
                        }
                    }
                    .addOnFailureListener {
                        isProcessing.set(false)
                        result.success(mapOf("distance" to -1.0, "status" to "no_face"))
                    }
            }
    }
}
