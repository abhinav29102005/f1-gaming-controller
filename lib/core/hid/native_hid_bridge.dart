import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeHidBridge {
  static const MethodChannel _channel = MethodChannel('com.example.f1_gaming_controller/hid');
  static const EventChannel _volumeChannel = EventChannel('com.example.f1_gaming_controller/volume_keys');

  static bool get isAndroidPlatform => !kIsWeb && Platform.isAndroid;

  static Future<bool> isBleHidSupported() async {
    if (!isAndroidPlatform) return false;
    try {
      final bool result = await _channel.invokeMethod('isBleHidSupported');
      return result;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> registerHidDevice(String deviceName) async {
    if (!isAndroidPlatform) return false;
    try {
      final bool result = await _channel.invokeMethod('registerHidDevice', {
        'deviceName': deviceName,
      });
      return result;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sendHidReport(Uint8List report) async {
    if (!isAndroidPlatform) return false;
    try {
      final bool result = await _channel.invokeMethod('sendHidReport', {
        'report': report,
      });
      return result;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sendUdpPacket(String host, int port, Uint8List data) async {
    if (!isAndroidPlatform) return false;
    try {
      final bool result = await _channel.invokeMethod('sendUdpPacket', {
        'host': host,
        'port': port,
        'data': data,
      });
      return result;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setVolumeKeyInterception(bool enabled) async {
    if (!isAndroidPlatform) return false;
    try {
      final bool result = await _channel.invokeMethod('setVolumeKeyInterception', {
        'enabled': enabled,
      });
      return result;
    } catch (_) {
      return false;
    }
  }

  static Stream<String> get volumeKeyStream {
    if (!isAndroidPlatform) return const Stream.empty();
    return _volumeChannel.receiveBroadcastStream().map((event) => event.toString());
  }
}
