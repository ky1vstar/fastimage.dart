import 'dart:math';
import 'dart:typed_data';

import 'package:fastimage/src/decoders/size_decoder.dart';
import 'package:fastimage/src/image_format.dart';
import 'package:fastimage/src/utils/extensions.dart';
import 'package:fastimage/src/image_size.dart';

/// ICO size decoder
///
/// File structure: https://en.wikipedia.org/wiki/ICO_(file_format)#Outline
class IcoSizeDecoder implements SizeDecoder {
  ImageFormat get imageFormat => ImageFormat.ico;
  int get signatureLength => _signature.length;
  int? get constantDataLength => null;

  static const _signature = [0x00, 0x00, 0x01];

  bool supportsFileExtension(String extension) => false;

  bool canDecodeData(Uint8List data) =>
      data.hasPrefix(_signature);

  ImageSize decode(Uint8List data) => decodeSize(data);

  static ImageSize decodeSize(Uint8List data) {
    final blob = ByteData.sublistView(data);
    final numberOfIcons = blob.getUint16(4, Endian.little);
    var width = 0;
    var height = 0;

    for (var i = 0; i < numberOfIcons; i++) {
      final offset = 6 + i * 16;
      var currentWidth = blob.getUint8(offset);
      var currentHeight = blob.getUint8(offset + 1);
      currentWidth = currentWidth == 0 ? 256 : currentWidth;
      currentHeight = currentHeight == 0 ? 256 : currentHeight;
      width = max(width, currentWidth);
      height = max(height, currentHeight);
    }

    return ImageSize(width, height);
  }
}