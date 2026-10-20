package apps.waleed.sunnah.wgoot.compass

import android.app.Activity
import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.view.Surface
import io.flutter.plugin.common.EventChannel

/**
 * Streams `[magneticHeadingDegrees, accuracyLevel]` to the Qibla screen.
 *
 * The heading is the direction the top of the screen faces, measured from
 * magnetic north; Dart applies the magnetic declination for the chosen city.
 * The fused rotation vector is preferred, falling back to accelerometer plus
 * magnetometer on devices without one. The magnetometer is always listened to
 * because its accuracy is what tells the user to calibrate.
 */
class CompassStreamHandler(private val activity: Activity) :
    EventChannel.StreamHandler, SensorEventListener {

    private val sensorManager =
        activity.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val rotationSensor: Sensor? =
        sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
    private val accelerometer: Sensor? =
        sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private val magnetometer: Sensor? =
        sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)

    private var sink: EventChannel.EventSink? = null
    private var accuracy = SensorManager.SENSOR_STATUS_UNRELIABLE

    private val rotation = FloatArray(9)
    private val remapped = FloatArray(9)
    private val orientation = FloatArray(3)
    private val gravity = FloatArray(3)
    private val geomagnetic = FloatArray(3)
    private var hasGravity = false
    private var hasGeomagnetic = false

    val isAvailable: Boolean
        get() = magnetometer != null && (rotationSensor != null || accelerometer != null)

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (!isAvailable) {
            events?.error("unavailable", "No compass sensor on this device", null)
            return
        }
        sink = events
        hasGravity = false
        hasGeomagnetic = false
        if (rotationSensor != null) {
            sensorManager.registerListener(this, rotationSensor, SensorManager.SENSOR_DELAY_UI)
        } else {
            sensorManager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_UI)
        }
        sensorManager.registerListener(this, magnetometer, SensorManager.SENSOR_DELAY_UI)
    }

    override fun onCancel(arguments: Any?) {
        sensorManager.unregisterListener(this)
        sink = null
    }

    override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {
        if (sensor.type == Sensor.TYPE_MAGNETIC_FIELD) {
            this.accuracy = accuracy
        }
    }

    override fun onSensorChanged(event: SensorEvent) {
        when (event.sensor.type) {
            Sensor.TYPE_ROTATION_VECTOR -> {
                SensorManager.getRotationMatrixFromVector(rotation, event.values)
                emit()
            }
            Sensor.TYPE_ACCELEROMETER -> {
                lowPass(event.values, gravity, hasGravity)
                hasGravity = true
                emitFromRawSensors()
            }
            Sensor.TYPE_MAGNETIC_FIELD -> {
                accuracy = event.accuracy
                if (rotationSensor == null) {
                    lowPass(event.values, geomagnetic, hasGeomagnetic)
                    hasGeomagnetic = true
                    emitFromRawSensors()
                }
            }
        }
    }

    private fun emitFromRawSensors() {
        if (hasGravity && hasGeomagnetic &&
            SensorManager.getRotationMatrix(rotation, null, gravity, geomagnetic)
        ) {
            emit()
        }
    }

    private fun emit() {
        val (axisX, axisY) = when (displayRotation()) {
            Surface.ROTATION_90 -> SensorManager.AXIS_Y to SensorManager.AXIS_MINUS_X
            Surface.ROTATION_180 -> SensorManager.AXIS_MINUS_X to SensorManager.AXIS_MINUS_Y
            Surface.ROTATION_270 -> SensorManager.AXIS_MINUS_Y to SensorManager.AXIS_X
            else -> SensorManager.AXIS_X to SensorManager.AXIS_Y
        }
        SensorManager.remapCoordinateSystem(rotation, axisX, axisY, remapped)
        SensorManager.getOrientation(remapped, orientation)
        val heading = (Math.toDegrees(orientation[0].toDouble()) + 360.0) % 360.0
        sink?.success(listOf(heading, accuracy.coerceIn(0, 3)))
    }

    @Suppress("DEPRECATION")
    private fun displayRotation(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            activity.display?.rotation ?: Surface.ROTATION_0
        } else {
            activity.windowManager.defaultDisplay.rotation
        }

    private fun lowPass(input: FloatArray, output: FloatArray, seeded: Boolean) {
        for (i in 0 until 3) {
            output[i] = if (seeded) {
                output[i] + LOW_PASS_ALPHA * (input[i] - output[i])
            } else {
                input[i]
            }
        }
    }

    private companion object {
        const val LOW_PASS_ALPHA = 0.2f
    }
}
