package com.example.f1_gaming_controller

import android.annotation.TargetApi
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothHidDevice
import android.bluetooth.BluetoothHidDeviceAppSdpSettings
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.KeyEvent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val HID_CHANNEL = "com.example.f1_gaming_controller/hid"
    private val VOLUME_CHANNEL = "com.example.f1_gaming_controller/volume_keys"
    private val FEEDBACK_CHANNEL = "com.example.f1_gaming_controller/feedback"

    private var bluetoothHidDevice: BluetoothHidDevice? = null
    private var connectedHostDevice: BluetoothDevice? = null
    private var isHidRegistered = false

    private var volumeEventSink: EventChannel.EventSink? = null
    private var interceptVolumeKeys = false

    private val executor = Executors.newFixedThreadPool(2)
    private var socket: DatagramSocket? = null

    // Standard Gamepad HID Descriptor (8-byte / 10-byte report)
    // Axes: X (Steering), Y (Throttle), Z (Brake), Hat (D-Pad), 16 Buttons
    private val GAMEPAD_DESCRIPTOR = byteArrayOf(
        0x05.toByte(), 0x01.toByte(), // USAGE_PAGE (Generic Desktop)
        0x09.toByte(), 0x05.toByte(), // USAGE (Gamepad)
        0xA1.toByte(), 0x01.toByte(), // COLLECTION (Application)
        0x85.toByte(), 0x01.toByte(), //   REPORT_ID (1)
        // Buttons (16 buttons -> 2 bytes)
        0x05.toByte(), 0x09.toByte(), //   USAGE_PAGE (Button)
        0x19.toByte(), 0x01.toByte(), //   USAGE_MINIMUM (Button 1)
        0x29.toByte(), 0x10.toByte(), //   USAGE_MAXIMUM (Button 16)
        0x15.toByte(), 0x00.toByte(), //   LOGICAL_MINIMUM (0)
        0x25.toByte(), 0x01.toByte(), //   LOGICAL_MAXIMUM (1)
        0x75.toByte(), 0x01.toByte(), //   REPORT_SIZE (1)
        0x95.toByte(), 0x10.toByte(), //   REPORT_COUNT (16)
        0x81.toByte(), 0x02.toByte(), //   INPUT (Data,Var,Abs)
        // Axes: X (Steering 16-bit signed -32768 to 32767), Y (Throttle 8-bit 0-255), Z (Brake 8-bit 0-255)
        0x05.toByte(), 0x01.toByte(), //   USAGE_PAGE (Generic Desktop)
        0x09.toByte(), 0x30.toByte(), //   USAGE (X - Steering)
        0x16.toByte(), 0x00.toByte(), 0x80.toByte(), // LOGICAL_MINIMUM (-32768)
        0x26.toByte(), 0xFF.toByte(), 0x7F.toByte(), // LOGICAL_MAXIMUM (32767)
        0x75.toByte(), 0x10.toByte(), //   REPORT_SIZE (16)
        0x95.toByte(), 0x01.toByte(), //   REPORT_COUNT (1)
        0x81.toByte(), 0x02.toByte(), //   INPUT (Data,Var,Abs)
        0x09.toByte(), 0x31.toByte(), //   USAGE (Y - Throttle)
        0x09.toByte(), 0x32.toByte(), //   USAGE (Z - Brake)
        0x15.toByte(), 0x00.toByte(), //   LOGICAL_MINIMUM (0)
        0x26.toByte(), 0xFF.toByte(), 0x00.toByte(), // LOGICAL_MAXIMUM (255)
        0x75.toByte(), 0x08.toByte(), //   REPORT_SIZE (8)
        0x95.toByte(), 0x02.toByte(), //   REPORT_COUNT (2)
        0x81.toByte(), 0x02.toByte(), //   INPUT (Data,Var,Abs)
        // Hat Switch (D-Pad, 4 bits + 4 bit padding)
        0x09.toByte(), 0x39.toByte(), //   USAGE (Hat Switch)
        0x15.toByte(), 0x01.toByte(), //   LOGICAL_MINIMUM (1)
        0x25.toByte(), 0x08.toByte(), //   LOGICAL_MAXIMUM (8)
        0x35.toByte(), 0x00.toByte(), //   PHYSICAL_MINIMUM (0)
        0x46.toByte(), 0x3E.toByte(), 0x01.toByte(), // PHYSICAL_MAXIMUM (315)
        0x65.toByte(), 0x14.toByte(), //   UNIT (Eng Rot: Angular Pos)
        0x75.toByte(), 0x04.toByte(), //   REPORT_SIZE (4)
        0x95.toByte(), 0x01.toByte(), //   REPORT_COUNT (1)
        0x81.toByte(), 0x42.toByte(), //   INPUT (Data,Var,Abs,Null)
        0x75.toByte(), 0x04.toByte(), //   REPORT_SIZE (4) - Padding
        0x95.toByte(), 0x01.toByte(), //   REPORT_COUNT (1)
        0x81.toByte(), 0x03.toByte(), //   INPUT (Cnst,Var,Abs)
        0xC0.toByte()                 // END_COLLECTION
    )

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HID_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isBleHidSupported" -> {
                    result.success(isBleHidSupported())
                }
                "registerHidDevice" -> {
                    val deviceName = call.argument<String>("deviceName") ?: "F1 Controller"
                    val success = registerHidDevice(deviceName)
                    result.success(success)
                }
                "sendHidReport" -> {
                    val report = call.argument<ByteArray>("report")
                    if (report != null) {
                        val sent = sendHidReport(report)
                        result.success(sent)
                    } else {
                        result.error("INVALID_REPORT", "Report payload is null", null)
                    }
                }
                "sendUdpPacket" -> {
                    val host = call.argument<String>("host") ?: ""
                    val port = call.argument<Int>("port") ?: 9999
                    val data = call.argument<ByteArray>("data")
                    if (data != null && host.isNotEmpty()) {
                        sendUdpPacketAsync(host, port, data)
                        result.success(true)
                    } else {
                        result.error("INVALID_UDP", "Host or payload invalid", null)
                    }
                }
                "setVolumeKeyInterception" -> {
                    interceptVolumeKeys = call.argument<Boolean>("enabled") ?: false
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FEEDBACK_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "triggerHaptic" -> {
                    val duration = (call.argument<Int>("duration") ?: 20).toLong()
                    val amplitude = call.argument<Int>("amplitude") ?: 200
                    triggerNativeHaptic(duration, amplitude)
                    result.success(true)
                }
                "playSpeakerTone" -> {
                    val freq = call.argument<Double>("freq") ?: 440.0
                    val durationMs = call.argument<Int>("durationMs") ?: 50
                    val vol = (call.argument<Double>("volume") ?: 1.0).toFloat()
                    playSynthTone(freq, durationMs, vol)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, VOLUME_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    volumeEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    volumeEventSink = null
                }
            }
        )

        initBluetoothProfile()
    }

    private fun triggerNativeHaptic(durationMs: Long, amplitude: Int) {
        try {
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vibratorManager?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            } ?: return

            if (!vibrator.hasVibrator()) return

            val amp = amplitude.coerceIn(1, 255)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val effect = VibrationEffect.createOneShot(durationMs, amp)
                vibrator.vibrate(effect)
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(durationMs)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun playSynthTone(frequency: Double, durationMs: Int, volume: Float = 1.0f) {
        executor.execute {
            try {
                val sampleRate = 44100
                val numSamples = (durationMs * sampleRate) / 1000
                if (numSamples <= 0) return@execute

                val sample = DoubleArray(numSamples)
                val generatedSnd = ByteArray(2 * numSamples)

                for (i in 0 until numSamples) {
                    sample[i] = Math.sin(2 * Math.PI * i / (sampleRate / frequency))
                }

                var idx = 0
                for (i in 0 until numSamples) {
                    val envelope = Math.exp(-4.0 * i / numSamples)
                    val val16 = (sample[i] * 32767 * volume * envelope).toInt().toShort()
                    generatedSnd[idx++] = (val16.toInt() and 0x00ff).toByte()
                    generatedSnd[idx++] = (val16.toInt() and 0xff00 ushr 8).toByte()
                }

                val audioTrack = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    AudioTrack.Builder()
                        .setAudioAttributes(
                            AudioAttributes.Builder()
                                .setUsage(AudioAttributes.USAGE_GAME)
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
                        .setBufferSizeInBytes(generatedSnd.size)
                        .setTransferMode(AudioTrack.MODE_STATIC)
                        .build()
                } else {
                    @Suppress("DEPRECATION")
                    AudioTrack(
                        AudioManager.STREAM_MUSIC,
                        sampleRate,
                        AudioFormat.CHANNEL_OUT_MONO,
                        AudioFormat.ENCODING_PCM_16BIT,
                        generatedSnd.size,
                        AudioTrack.MODE_STATIC
                    )
                }

                audioTrack.write(generatedSnd, 0, generatedSnd.size)
                audioTrack.play()
                Thread.sleep(durationMs.toLong() + 10)
                audioTrack.release()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun isBleHidSupported(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return false
        val adapter = BluetoothAdapter.getDefaultAdapter() ?: return false
        return adapter.isEnabled
    }

    private fun initBluetoothProfile() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val adapter = BluetoothAdapter.getDefaultAdapter() ?: return
            adapter.getProfileProxy(applicationContext, object : BluetoothProfile.ServiceListener {
                override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                    if (profile == BluetoothProfile.HID_DEVICE) {
                        bluetoothHidDevice = proxy as BluetoothHidDevice
                    }
                }

                override fun onServiceDisconnected(profile: Int) {
                    if (profile == BluetoothProfile.HID_DEVICE) {
                        bluetoothHidDevice = null
                        isHidRegistered = false
                    }
                }
            }, BluetoothProfile.HID_DEVICE)
        }
    }

    @TargetApi(Build.VERSION_CODES.P)
    private fun registerHidDevice(name: String): Boolean {
        val hidDev = bluetoothHidDevice ?: return false
        if (isHidRegistered) return true

        val sdpSettings = BluetoothHidDeviceAppSdpSettings(
            name,
            "F1 Racing Controller",
            "Antigravity F1",
            BluetoothHidDevice.SUBCLASS1_COMBO,
            GAMEPAD_DESCRIPTOR
        )

        return hidDev.registerApp(sdpSettings, null, null, executor, object : BluetoothHidDevice.Callback() {
            override fun onAppStatusChanged(device: BluetoothDevice?, registered: Boolean) {
                isHidRegistered = registered
            }

            override fun onConnectionStateChanged(device: BluetoothDevice, state: Int) {
                if (state == BluetoothProfile.STATE_CONNECTED) {
                    connectedHostDevice = device
                } else if (state == BluetoothProfile.STATE_DISCONNECTED) {
                    if (connectedHostDevice == device) {
                        connectedHostDevice = null
                    }
                }
            }
        })
    }

    @TargetApi(Build.VERSION_CODES.P)
    private fun sendHidReport(report: ByteArray): Boolean {
        val hidDev = bluetoothHidDevice ?: return false
        val device = connectedHostDevice ?: return false
        return hidDev.sendReport(device, 1, report)
    }

    private fun sendUdpPacketAsync(host: String, port: Int, data: ByteArray) {
        executor.execute {
            try {
                if (socket == null || socket!!.isClosed) {
                    socket = DatagramSocket()
                }
                val address = InetAddress.getByName(host)
                val packet = DatagramPacket(data, data.size, address, port)
                socket?.send(packet)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (interceptVolumeKeys) {
            when (keyCode) {
                KeyEvent.KEYCODE_VOLUME_UP -> {
                    volumeEventSink?.success("VOLUME_UP_DOWN")
                    return true
                }
                KeyEvent.KEYCODE_VOLUME_DOWN -> {
                    volumeEventSink?.success("VOLUME_DOWN_DOWN")
                    return true
                }
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        if (interceptVolumeKeys) {
            when (keyCode) {
                KeyEvent.KEYCODE_VOLUME_UP -> {
                    volumeEventSink?.success("VOLUME_UP_UP")
                    return true
                }
                KeyEvent.KEYCODE_VOLUME_DOWN -> {
                    volumeEventSink?.success("VOLUME_DOWN_UP")
                    return true
                }
            }
        }
        return super.onKeyUp(keyCode, event)
    }

    override fun onDestroy() {
        super.onDestroy()
        socket?.close()
        executor.shutdown()
    }
}

