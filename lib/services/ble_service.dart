import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/glasses_device.dart';
import '../utils/glasses_protocol.dart';

enum ConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  streaming,
}

class BleService extends ChangeNotifier {
  // Service UUIDs from the SDK
  static const String serviceUuid1 = "0000ae00-0000-1000-8000-00805f9b34fb";
  static const String serviceUuid2 = "0000ae30-0000-1000-8000-00805f9b34fb";
  
  // Characteristic UUIDs
  static const String writeCharUuid = "0000ae01-0000-1000-8000-00805f9b34fb";
  static const String notifyCharUuid = "0000ae02-0000-1000-8000-00805f9b34fb";
  static const String videoCharUuid = "0000ae31-0000-1000-8000-00805f9b34fb";

  ConnectionState _connectionState = ConnectionState.disconnected;
  ConnectionState get connectionState => _connectionState;

  final List<GlassesDevice> _discoveredDevices = [];
  List<GlassesDevice> get discoveredDevices => _discoveredDevices;

  BluetoothDevice? _connectedDevice;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;
  BluetoothCharacteristic? _videoCharacteristic;

  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _notifySubscription;
  StreamSubscription? _videoSubscription;

  // Device info
  int _batteryLevel = 0;
  int get batteryLevel => _batteryLevel;
  
  bool _isCharging = false;
  bool get isCharging => _isCharging;

  String _firmwareVersion = '';
  String get firmwareVersion => _firmwareVersion;

  // Video stream
  final StreamController<Uint8List> _videoStreamController = 
      StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get videoStream => _videoStreamController.stream;

  // Media counts
  int _photoCount = 0;
  int _videoCount = 0;
  int _audioCount = 0;
  int get photoCount => _photoCount;
  int get videoCount => _videoCount;
  int get audioCount => _audioCount;

  String _statusMessage = '';
  String get statusMessage => _statusMessage;

  BleService() {
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    // Check if Bluetooth is supported
    if (await FlutterBluePlus.isSupported == false) {
      _statusMessage = 'Bluetooth not supported';
      notifyListeners();
      return;
    }

    // Listen to adapter state
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.off) {
        _statusMessage = 'Bluetooth is OFF';
        _connectionState = ConnectionState.disconnected;
        notifyListeners();
      }
    });
  }

  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return statuses.values.every(
      (status) => status.isGranted || status.isLimited,
    );
  }

  Future<void> startScan() async {
    if (!await requestPermissions()) {
      _statusMessage = 'Bluetooth permissions denied';
      notifyListeners();
      return;
    }

    // Turn on Bluetooth if needed
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOn();
    }

    _discoveredDevices.clear();
    _connectionState = ConnectionState.scanning;
    _statusMessage = 'Scanning for glasses...';
    notifyListeners();

    // Stop any existing scan
    await FlutterBluePlus.stopScan();

    // Start scanning
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        // Filter for glasses devices (look for specific names or service UUIDs)
        final deviceName = result.device.platformName.toLowerCase();
        final isGlassesDevice = deviceName.contains('glass') ||
            deviceName.contains('qc') ||
            deviceName.contains('smart') ||
            result.advertisementData.serviceUuids.any((uuid) =>
                uuid.toString().toLowerCase().contains('ae00') ||
                uuid.toString().toLowerCase().contains('ae30'));

        if (result.device.platformName.isNotEmpty) {
          final existingIndex = _discoveredDevices.indexWhere(
            (d) => d.device.remoteId == result.device.remoteId,
          );

          final glassesDevice = GlassesDevice(
            device: result.device,
            rssi: result.rssi,
            isGlassesDevice: isGlassesDevice,
          );

          if (existingIndex >= 0) {
            _discoveredDevices[existingIndex] = glassesDevice;
          } else {
            _discoveredDevices.add(glassesDevice);
          }
          
          // Sort by signal strength
          _discoveredDevices.sort((a, b) => b.rssi.compareTo(a.rssi));
          notifyListeners();
        }
      }
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      androidUsesFineLocation: true,
    );

    // After scan completes
    _connectionState = ConnectionState.disconnected;
    _statusMessage = '${_discoveredDevices.length} devices found';
    notifyListeners();
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _connectionState = ConnectionState.disconnected;
    notifyListeners();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      _connectionState = ConnectionState.connecting;
      _statusMessage = 'Connecting to ${device.platformName}...';
      notifyListeners();

      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;

      // Listen for disconnection
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      // Discover services
      _statusMessage = 'Discovering services...';
      notifyListeners();
      
      List<BluetoothService> services = await device.discoverServices();
      
      // Find our characteristics
      for (var service in services) {
        final serviceUuidStr = service.uuid.toString().toLowerCase();
        
        if (serviceUuidStr.contains('ae00')) {
          for (var char in service.characteristics) {
            final charUuidStr = char.uuid.toString().toLowerCase();
            if (charUuidStr.contains('ae01')) {
              _writeCharacteristic = char;
            } else if (charUuidStr.contains('ae02')) {
              _notifyCharacteristic = char;
            }
          }
        } else if (serviceUuidStr.contains('ae30')) {
          for (var char in service.characteristics) {
            final charUuidStr = char.uuid.toString().toLowerCase();
            if (charUuidStr.contains('ae31')) {
              _videoCharacteristic = char;
            }
          }
        }
      }

      // Subscribe to notifications
      if (_notifyCharacteristic != null) {
        await _notifyCharacteristic!.setNotifyValue(true);
        _notifySubscription = _notifyCharacteristic!.onValueReceived.listen(
          _handleNotification,
        );
      }

      _connectionState = ConnectionState.connected;
      _statusMessage = 'Connected to ${device.platformName}';
      notifyListeners();

      // Get initial device info
      await Future.delayed(const Duration(milliseconds: 500));
      await getBatteryLevel();
      await getDeviceVersion();
      await getMediaInfo();

    } catch (e) {
      _statusMessage = 'Connection failed: $e';
      _connectionState = ConnectionState.disconnected;
      notifyListeners();
    }
  }

  void _handleDisconnection() {
    _connectedDevice = null;
    _writeCharacteristic = null;
    _notifyCharacteristic = null;
    _videoCharacteristic = null;
    _connectionSubscription?.cancel();
    _notifySubscription?.cancel();
    _videoSubscription?.cancel();
    _connectionState = ConnectionState.disconnected;
    _statusMessage = 'Disconnected';
    notifyListeners();
  }

  void _handleNotification(List<int> data) {
    if (data.isEmpty) return;

    final response = GlassesProtocol.parseResponse(Uint8List.fromList(data));
    
    switch (response.command) {
      case GlassesCommand.getBattery:
        if (response.data.length >= 2) {
          _batteryLevel = response.data[0];
          _isCharging = response.data[1] == 1;
          notifyListeners();
        }
        break;
      case GlassesCommand.getVersion:
        _firmwareVersion = String.fromCharCodes(response.data);
        notifyListeners();
        break;
      case GlassesCommand.getMedia:
        if (response.data.length >= 12) {
          _photoCount = _bytesToInt(response.data.sublist(0, 4));
          _videoCount = _bytesToInt(response.data.sublist(4, 8));
          _audioCount = _bytesToInt(response.data.sublist(8, 12));
          notifyListeners();
        }
        break;
      case GlassesCommand.dataUpdate:
        // Handle real-time updates
        _handleDataUpdate(response.data);
        break;
      default:
        break;
    }
  }

  void _handleDataUpdate(Uint8List data) {
    if (data.isEmpty) return;
    
    final updateType = data[0];
    switch (updateType) {
      case 0x0B: // Power update
        if (data.length >= 3) {
          _batteryLevel = data[1];
          _isCharging = data[2] == 1;
          notifyListeners();
        }
        break;
    }
  }

  int _bytesToInt(List<int> bytes) {
    int value = 0;
    for (int i = 0; i < bytes.length; i++) {
      value |= bytes[i] << (8 * i);
    }
    return value;
  }

  Future<void> _sendCommand(Uint8List data) async {
    if (_writeCharacteristic == null) {
      _statusMessage = 'Not connected';
      notifyListeners();
      return;
    }

    try {
      await _writeCharacteristic!.write(data.toList(), withoutResponse: false);
    } catch (e) {
      _statusMessage = 'Command failed: $e';
      notifyListeners();
    }
  }

  // Device commands
  Future<void> getBatteryLevel() async {
    final cmd = GlassesProtocol.createCommand(GlassesCommand.getBattery);
    await _sendCommand(cmd);
  }

  Future<void> getDeviceVersion() async {
    final cmd = GlassesProtocol.createCommand(GlassesCommand.getVersion);
    await _sendCommand(cmd);
  }

  Future<void> getMediaInfo() async {
    final cmd = GlassesProtocol.createCommand(GlassesCommand.getMedia);
    await _sendCommand(cmd);
  }

  Future<void> takePhoto() async {
    final cmd = GlassesProtocol.createCommand(
      GlassesCommand.setMode,
      data: Uint8List.fromList([0x01]), // Photo mode
    );
    await _sendCommand(cmd);
    _statusMessage = 'Taking photo...';
    notifyListeners();
  }

  Future<void> startVideoRecording() async {
    final cmd = GlassesProtocol.createCommand(
      GlassesCommand.setMode,
      data: Uint8List.fromList([0x02]), // Video mode
    );
    await _sendCommand(cmd);
    _statusMessage = 'Recording video...';
    notifyListeners();
  }

  Future<void> stopVideoRecording() async {
    final cmd = GlassesProtocol.createCommand(
      GlassesCommand.setMode,
      data: Uint8List.fromList([0x03]), // Video stop
    );
    await _sendCommand(cmd);
    _statusMessage = 'Video recording stopped';
    notifyListeners();
  }

  Future<void> startVideoStream() async {
    if (_videoCharacteristic == null) {
      _statusMessage = 'Video streaming not available';
      notifyListeners();
      return;
    }

    try {
      // Enable video streaming mode
      final cmd = GlassesProtocol.createCommand(
        GlassesCommand.setMode,
        data: Uint8List.fromList([0x04]), // Transfer mode
      );
      await _sendCommand(cmd);

      // Subscribe to video characteristic
      await _videoCharacteristic!.setNotifyValue(true);
      _videoSubscription = _videoCharacteristic!.onValueReceived.listen(
        (data) {
          _videoStreamController.add(Uint8List.fromList(data));
        },
      );

      _connectionState = ConnectionState.streaming;
      _statusMessage = 'Video streaming...';
      notifyListeners();
    } catch (e) {
      _statusMessage = 'Failed to start stream: $e';
      notifyListeners();
    }
  }

  Future<void> stopVideoStream() async {
    _videoSubscription?.cancel();
    
    final cmd = GlassesProtocol.createCommand(
      GlassesCommand.setMode,
      data: Uint8List.fromList([0x09]), // Transfer stop
    );
    await _sendCommand(cmd);

    _connectionState = ConnectionState.connected;
    _statusMessage = 'Stream stopped';
    notifyListeners();
  }

  Future<void> disconnect() async {
    await stopVideoStream();
    await _connectedDevice?.disconnect();
    _handleDisconnection();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _notifySubscription?.cancel();
    _videoSubscription?.cancel();
    _videoStreamController.close();
    super.dispose();
  }
}


