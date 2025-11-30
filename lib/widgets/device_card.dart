import 'package:flutter/material.dart';
import '../models/glasses_device.dart';

class DeviceCard extends StatelessWidget {
  final GlassesDevice device;
  final bool isConnected;
  final VoidCallback onTap;

  const DeviceCard({
    super.key,
    required this.device,
    required this.isConnected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isConnected
                ? [
                    const Color(0xFF00E5FF).withOpacity(0.15),
                    const Color(0xFF00B4D8).withOpacity(0.08),
                  ]
                : device.isGlassesDevice
                    ? [
                        const Color(0xFFFF0080).withOpacity(0.1),
                        const Color(0xFF1A1A24),
                      ]
                    : [
                        const Color(0xFF1A1A24),
                        const Color(0xFF12121A),
                      ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isConnected
                ? const Color(0xFF00E5FF).withOpacity(0.5)
                : device.isGlassesDevice
                    ? const Color(0xFFFF0080).withOpacity(0.3)
                    : const Color(0xFF2A2A3A),
            width: isConnected ? 2 : 1,
          ),
          boxShadow: isConnected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Device icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isConnected
                      ? [const Color(0xFF00E5FF), const Color(0xFF00B4D8)]
                      : device.isGlassesDevice
                          ? [const Color(0xFFFF0080), const Color(0xFFCC0066)]
                          : [const Color(0xFF2A2A3A), const Color(0xFF1A1A24)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                device.isGlassesDevice ? Icons.visibility : Icons.bluetooth,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Device info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          device.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (device.isGlassesDevice)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF0080).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'GLASSES',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF0080),
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    device.id,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white38,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            // Signal strength
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildSignalBars(),
                const SizedBox(height: 4),
                Text(
                  '${device.rssi} dBm',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            
            // Arrow
            Icon(
              isConnected ? Icons.check_circle : Icons.arrow_forward_ios,
              color: isConnected
                  ? const Color(0xFF00E5FF)
                  : const Color(0xFF4A4A5A),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalBars() {
    return Row(
      children: List.generate(4, (index) {
        final isActive = index < device.signalBars;
        return Container(
          width: 4,
          height: 8 + (index * 3).toDouble(),
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: isActive
                ? _getSignalColor()
                : const Color(0xFF2A2A3A),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Color _getSignalColor() {
    if (device.signalBars >= 3) return const Color(0xFF00FF88);
    if (device.signalBars >= 2) return const Color(0xFFFFAA00);
    return const Color(0xFFFF4444);
  }
}


