import 'dart:typed_data';

import 'package:fastimage/src/decoders/size_decoder.dart';
import 'package:fastimage/src/image_format.dart';
import 'package:fastimage/src/internal_exceptions.dart';
import 'package:fastimage/src/utils/extensions.dart';
import 'package:fastimage/src/image_size.dart';

class WebpSizeDecoder implements SizeDecoder {
  ImageFormat get imageFormat => ImageFormat.webp;
  int get signatureLength => _signature.length;
  int get constantDataLength => 30;

  static const _signature = [0x52, 0x49];

  bool supportsFileExtension(String extension) => extension == "webp";

  bool canDecodeData(Uint8List data) {
    if (data.hasPrefix(_signature)) {
      return data.sublistView(8, 12).hasAsciiPrefix("WEBP");
    } else {
      return false;
    }
  }

  ImageSize decode(Uint8List data) {
    final blob = ByteData.sublistView(data);
    final vp8 = data.sublistView(12, 16);
    if (vp8.hasAsciiPrefix("VP8 ")) {
      final offset = 26;
      return ImageSize(
          blob.getUint16(offset, Endian.little),
          blob.getUint16(offset + 2, Endian.little)
      );
    } else if (vp8.hasAsciiPrefix("VP8L")) {
      final offset = 21;
      final b1 = blob.getUint8(offset + 0);
      final b2 = blob.getUint8(offset + 1);
      final b3 = blob.getUint8(offset + 2);
      final b4 = blob.getUint8(offset + 3);

      return ImageSize(
          1 + (((b2 & 0x3f) << 8) | b1),
          1 + (((b4 & 0xF) << 10) | (b3 << 2) | ((b2 & 0xC0) >> 6))
      );
    } else if (vp8.hasAsciiPrefix("VP8X")) {
      var offset = 20;
      final flags = blob.getUint8(offset);
      offset += 4;

      final b1 = blob.getUint8(offset + 0);
      final b2 = blob.getUint8(offset + 1);
      final b3 = blob.getUint8(offset + 2);
      final b4 = blob.getUint8(offset + 3);
      final b5 = blob.getUint8(offset + 4);
      final b6 = blob.getUint8(offset + 5);
      final width = 1 + b1 + (b2 << 8) + (b3 << 16);
      final height = 1 + b4 + (b5 << 8) + (b6 << 16);

      if (flags & 8 > 0) { // exif
        // parse exif for orientation
        // TODO: find or create test images for this
      }

      return ImageSize(width, height);
    } else {
      throw CorruptedDataException();
    }
  }
}