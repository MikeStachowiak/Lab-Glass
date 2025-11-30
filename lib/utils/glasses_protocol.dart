import 'dart:typed_data';

/// Command codes matching the iOS SDK protocol
enum GlassesCommand {
  startDfu(0x01),
  initDfuParams(0x02),
  receiveFirmware(0x03),
  validateFirmware(0x04),
  activateAndReset(0x05),
  checkStatus(0x06),
  setupDevice(0x40),
  setMode(0x41),
  getBattery(0x42),
  getVersion(0x43),
  voiceWakeup(0x44),
  voiceHeartbeat(0x45),
  wearingDetection(0x46),
  deviceConfig(0x47),
  aiSpeak(0x48),
  volume(0x51),
  btStatus(0x52),
  dataUpdate(0x73),
  getMedia(0x53),
  deleteMedia(0x54),
  thumbnail(0xFD),
  otaLink(0xFC),
  unknown(0xFF);

  final int code;
  const GlassesCommand(this.code);

  static GlassesCommand fromCode(int code) {
    return GlassesCommand.values.firstWhere(
      (cmd) => cmd.code == code,
      orElse: () => GlassesCommand.unknown,
    );
  }
}

/// Device operating modes
enum DeviceMode {
  unknown(0x00),
  photo(0x01),
  video(0x02),
  videoStop(0x03),
  transfer(0x04),
  ota(0x05),
  aiPhoto(0x06),
  speechRecognition(0x07),
  audio(0x08),
  transferStop(0x09),
  factoryReset(0x0A),
  speechRecognitionStop(0x0B),
  audioStop(0x0C),
  findDevice(0x0D),
  restart(0x0E),
  noPowerP2P(0x0F),
  speakStart(0x10),
  speakStop(0x11),
  translateStart(0x12),
  translateStop(0x13);

  final int code;
  const DeviceMode(this.code);
}

/// AI speaking modes
enum AISpeakMode {
  start(0x01),
  hold(0x02),
  stop(0x03),
  thinkingStart(0x04),
  thinkingHold(0x05),
  thinkingStop(0x06),
  noNet(0xF1);

  final int code;
  const AISpeakMode(this.code);
}

/// Protocol response from glasses
class GlassesResponse {
  final GlassesCommand command;
  final int status;
  final Uint8List data;

  GlassesResponse({
    required this.command,
    required this.status,
    required this.data,
  });

  bool get isSuccess => status == 0x00;
}

/// Protocol helper for creating and parsing commands
class GlassesProtocol {
  // Packet header
  static const int packetHeader = 0xAA;
  
  /// Create a command packet to send to glasses
  static Uint8List createCommand(GlassesCommand command, {Uint8List? data}) {
    final dataLength = data?.length ?? 0;
    final totalLength = 4 + dataLength; // header + length + cmd + checksum + data
    
    final buffer = Uint8List(totalLength);
    buffer[0] = packetHeader; // Header
    buffer[1] = (dataLength + 1) & 0xFF; // Length (cmd + data)
    buffer[2] = command.code; // Command
    
    if (data != null) {
      buffer.setRange(3, 3 + dataLength, data);
    }
    
    // Calculate checksum (XOR of all bytes except header)
    int checksum = 0;
    for (int i = 1; i < totalLength - 1; i++) {
      checksum ^= buffer[i];
    }
    buffer[totalLength - 1] = checksum;
    
    return buffer;
  }

  /// Create a command with mode parameter
  static Uint8List createModeCommand(DeviceMode mode) {
    return createCommand(
      GlassesCommand.setMode,
      data: Uint8List.fromList([mode.code]),
    );
  }

  /// Parse response from glasses
  static GlassesResponse parseResponse(Uint8List data) {
    if (data.length < 4) {
      return GlassesResponse(
        command: GlassesCommand.unknown,
        status: 0xFF,
        data: Uint8List(0),
      );
    }

    // Verify header
    if (data[0] != packetHeader) {
      return GlassesResponse(
        command: GlassesCommand.unknown,
        status: 0xFF,
        data: Uint8List(0),
      );
    }

    final length = data[1];
    final command = GlassesCommand.fromCode(data[2]);
    final status = data.length > 3 ? data[3] : 0xFF;
    
    Uint8List responseData = Uint8List(0);
    if (length > 2 && data.length > 4) {
      responseData = data.sublist(4, 4 + length - 2);
    }

    return GlassesResponse(
      command: command,
      status: status,
      data: responseData,
    );
  }

  /// Calculate CRC16 for firmware updates
  static int calculateCrc16(Uint8List data) {
    int crc = 0xFFFF;
    for (int byte in data) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x0001) != 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc >>= 1;
        }
      }
    }
    return crc;
  }

  /// Calculate checksum for firmware updates
  static int calculateChecksum(Uint8List data) {
    int sum = 0;
    for (int byte in data) {
      sum += byte;
    }
    return sum & 0xFFFF;
  }
}


