import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../widgets/device_card.dart';
import '../widgets/scan_animation.dart';
import 'device_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A0F),
              Color(0xFF12121A),
              Color(0xFF0A0A0F),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<BleService>(
            builder: (context, bleService, _) {
              return Column(
                children: [
                  _buildHeader(bleService),
                  _buildStatusBar(bleService),
                  Expanded(
                    child: bleService.connectionState == BleConnectionState.scanning
                        ? _buildScanningView()
                        : _buildDeviceList(bleService),
                  ),
                  _buildBottomControls(bleService),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BleService bleService) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: bleService.connectionState == BleConnectionState.connected
                    ? _pulseAnimation.value
                    : 1.0,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: bleService.connectionState == BleConnectionState.connected
                          ? [const Color(0xFF00E5FF), const Color(0xFF00B4D8)]
                          : [const Color(0xFF2A2A3A), const Color(0xFF1A1A24)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: bleService.connectionState == BleConnectionState.connected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: const Icon(
                    Icons.visibility,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SMART GLASSES',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getConnectionStatusText(bleService.connectionState),
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1,
                    color: _getConnectionStatusColor(bleService.connectionState),
                  ),
                ),
              ],
            ),
          ),
          if (bleService.connectionState == BleConnectionState.connected)
            _buildBatteryIndicator(bleService),
        ],
      ),
    );
  }

  Widget _buildBatteryIndicator(BleService bleService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A3A)),
      ),
      child: Row(
        children: [
          Icon(
            bleService.isCharging ? Icons.bolt : Icons.battery_std,
            color: bleService.batteryLevel > 20
                ? const Color(0xFF00E5FF)
                : const Color(0xFFFF4444),
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            '${bleService.batteryLevel}%',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(BleService bleService) {
    if (bleService.statusMessage.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF00E5FF).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          if (bleService.connectionState == BleConnectionState.scanning ||
              bleService.connectionState == BleConnectionState.connecting)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00E5FF),
              ),
            )
          else
            const Icon(
              Icons.info_outline,
              color: Color(0xFF00E5FF),
              size: 16,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              bleService.statusMessage,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningView() {
    return const Center(
      child: ScanAnimation(),
    );
  }

  Widget _buildDeviceList(BleService bleService) {
    if (bleService.discoveredDevices.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: bleService.discoveredDevices.length,
      itemBuilder: (context, index) {
        final device = bleService.discoveredDevices[index];
        return DeviceCard(
          device: device,
          isConnected: bleService.connectedDevice?.remoteId == device.device.remoteId,
          onTap: () async {
            if (bleService.connectedDevice?.remoteId == device.device.remoteId) {
              // Already connected, go to device screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeviceScreen(),
                ),
              );
            } else {
              // Connect to device
              await bleService.connectToDevice(device.device);
              if (bleService.connectionState == BleConnectionState.connected && mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeviceScreen(),
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A24),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: const Color(0xFF2A2A3A),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.bluetooth_searching,
              size: 48,
              color: Color(0xFF4A4A5A),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'NO DEVICES FOUND',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap scan to search for glasses',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BleService bleService) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: bleService.connectionState == BleConnectionState.scanning
                  ? () => bleService.stopScan()
                  : () => bleService.startScan(),
              icon: Icon(
                bleService.connectionState == BleConnectionState.scanning
                    ? Icons.stop
                    : Icons.radar,
              ),
              label: Text(
                bleService.connectionState == BleConnectionState.scanning
                    ? 'STOP SCAN'
                    : 'SCAN',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: bleService.connectionState == BleConnectionState.scanning
                    ? const Color(0xFFFF0080)
                    : const Color(0xFF00E5FF),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (bleService.connectionState == BleConnectionState.connected) ...[
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeviceScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A24),
                foregroundColor: const Color(0xFF00E5FF),
                padding: const EdgeInsets.all(16),
                side: const BorderSide(color: Color(0xFF00E5FF)),
              ),
              child: const Icon(Icons.arrow_forward),
            ),
          ],
        ],
      ),
    );
  }

  String _getConnectionStatusText(BleConnectionState state) {
    switch (state) {
      case BleConnectionState.disconnected:
        return 'DISCONNECTED';
      case BleConnectionState.scanning:
        return 'SCANNING...';
      case BleConnectionState.connecting:
        return 'CONNECTING...';
      case BleConnectionState.connected:
        return 'CONNECTED';
      case BleConnectionState.streaming:
        return 'STREAMING';
    }
  }

  Color _getConnectionStatusColor(BleConnectionState state) {
    switch (state) {
      case BleConnectionState.disconnected:
        return Colors.white38;
      case BleConnectionState.scanning:
        return const Color(0xFFFF0080);
      case BleConnectionState.connecting:
        return const Color(0xFFFFAA00);
      case BleConnectionState.connected:
      case BleConnectionState.streaming:
        return const Color(0xFF00E5FF);
    }
  }
}





