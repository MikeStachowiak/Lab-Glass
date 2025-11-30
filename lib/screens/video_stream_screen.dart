import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';

class VideoStreamScreen extends StatefulWidget {
  const VideoStreamScreen({super.key});

  @override
  State<VideoStreamScreen> createState() => _VideoStreamScreenState();
}

class _VideoStreamScreenState extends State<VideoStreamScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  bool _isFullscreen = false;
  final List<Uint8List> _frameBuffer = [];
  Uint8List? _currentFrame;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start streaming when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startStreaming();
    });
  }

  void _startStreaming() {
    final bleService = Provider.of<BleService>(context, listen: false);
    bleService.startVideoStream();
    
    // Listen to video stream
    bleService.videoStream.listen((data) {
      _handleVideoData(data);
    });
  }

  void _handleVideoData(Uint8List data) {
    // Accumulate frame data
    _frameBuffer.add(data);
    
    // Try to decode frame (simplified - real implementation would need proper JPEG/H264 decoding)
    if (_isFrameComplete(data)) {
      final frameData = _assembleFrame();
      if (frameData != null && mounted) {
        setState(() {
          _currentFrame = frameData;
        });
        _frameBuffer.clear();
      }
    }
  }

  bool _isFrameComplete(Uint8List data) {
    // Check for JPEG end marker (0xFFD9)
    if (data.length >= 2) {
      return data[data.length - 2] == 0xFF && data[data.length - 1] == 0xD9;
    }
    return false;
  }

  Uint8List? _assembleFrame() {
    if (_frameBuffer.isEmpty) return null;
    
    int totalLength = 0;
    for (var chunk in _frameBuffer) {
      totalLength += chunk.length;
    }
    
    final frame = Uint8List(totalLength);
    int offset = 0;
    for (var chunk in _frameBuffer) {
      frame.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    
    return frame;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    // Stop streaming when leaving screen
    final bleService = Provider.of<BleService>(context, listen: false);
    bleService.stopVideoStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<BleService>(
          builder: (context, bleService, _) {
            return Stack(
              children: [
                // Video display area
                Positioned.fill(
                  child: GestureDetector(
                    onDoubleTap: () {
                      setState(() {
                        _isFullscreen = !_isFullscreen;
                      });
                    },
                    child: _buildVideoArea(bleService),
                  ),
                ),

                // Top controls (hidden in fullscreen)
                if (!_isFullscreen) _buildTopControls(context, bleService),

                // Bottom controls
                _buildBottomControls(context, bleService),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoArea(BleService bleService) {
    if (bleService.connectionState == BleConnectionState.streaming &&
        _currentFrame != null) {
      return Image.memory(
        _currentFrame!,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(bleService);
        },
      );
    }
    return _buildPlaceholder(bleService);
  }

  Widget _buildPlaceholder(BleService bleService) {
    final isStreaming = bleService.connectionState == BleConnectionState.streaming;
    
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            const Color(0xFF1A1A24),
            const Color(0xFF0A0A0F),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isStreaming
                          ? const Color(0xFF00E5FF)
                              .withOpacity(_pulseAnimation.value)
                          : const Color(0xFF2A2A3A),
                      width: 3,
                    ),
                    boxShadow: isStreaming
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00E5FF)
                                  .withOpacity(_pulseAnimation.value * 0.5),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    isStreaming ? Icons.videocam : Icons.videocam_off,
                    size: 48,
                    color: isStreaming
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF4A4A5A),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              isStreaming ? 'STREAMING...' : 'NO VIDEO SIGNAL',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
                color: isStreaming
                    ? const Color(0xFF00E5FF)
                    : Colors.white38,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isStreaming
                  ? 'Waiting for video data'
                  : 'Tap play to start streaming',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls(BuildContext context, BleService bleService) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LIVE STREAM',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: bleService.connectionState ==
                                  BleConnectionState.streaming
                              ? const Color(0xFFFF4444)
                              : const Color(0xFF4A4A5A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        bleService.connectionState == BleConnectionState.streaming
                            ? 'LIVE'
                            : 'OFFLINE',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1,
                          color: bleService.connectionState ==
                                  BleConnectionState.streaming
                              ? const Color(0xFFFF4444)
                              : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Battery indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    bleService.isCharging ? Icons.bolt : Icons.battery_std,
                    color: bleService.batteryLevel > 20
                        ? const Color(0xFF00FF88)
                        : const Color(0xFFFF4444),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${bleService.batteryLevel}%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, BleService bleService) {
    final isStreaming = bleService.connectionState == BleConnectionState.streaming;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.9),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Take photo button
            _buildControlButton(
              icon: Icons.camera_alt,
              color: const Color(0xFF00E5FF),
              size: 48,
              onTap: () {
                bleService.takePhoto();
                _showSnackBar('Photo captured');
              },
            ),
            const SizedBox(width: 32),
            
            // Play/Stop streaming button
            _buildControlButton(
              icon: isStreaming ? Icons.stop : Icons.play_arrow,
              color: isStreaming
                  ? const Color(0xFFFF4444)
                  : const Color(0xFF00FF88),
              size: 72,
              isMain: true,
              onTap: () {
                if (isStreaming) {
                  bleService.stopVideoStream();
                } else {
                  bleService.startVideoStream();
                }
              },
            ),
            const SizedBox(width: 32),
            
            // Record button
            _buildControlButton(
              icon: Icons.fiber_manual_record,
              color: const Color(0xFFFF4444),
              size: 48,
              onTap: () {
                bleService.startVideoRecording();
                _showSnackBar('Recording started');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
    bool isMain = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isMain
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withOpacity(0.7)],
                )
              : null,
          color: isMain ? null : Colors.white.withOpacity(0.1),
          border: Border.all(
            color: color.withOpacity(isMain ? 0.5 : 0.3),
            width: 2,
          ),
          boxShadow: isMain
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Icon(
          icon,
          color: isMain ? Colors.white : color,
          size: size * 0.4,
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1A1A24),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}





