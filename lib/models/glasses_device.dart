import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class GlassesDevice {
  final BluetoothDevice device;
  final int rssi;
  final bool isGlassesDevice;

  GlassesDevice({
    required this.device,
    required this.rssi,
    this.isGlassesDevice = false,
  });

  String get name => device.platformName.isEmpty ? 'Unknown' : device.platformName;
  
  String get id => device.remoteId.toString();

  String get signalStrength {
    if (rssi >= -50) return 'Excellent';
    if (rssi >= -60) return 'Good';
    if (rssi >= -70) return 'Fair';
    return 'Weak';
  }

  int get signalBars {
    if (rssi >= -50) return 4;
    if (rssi >= -60) return 3;
    if (rssi >= -70) return 2;
    return 1;
  }
}


