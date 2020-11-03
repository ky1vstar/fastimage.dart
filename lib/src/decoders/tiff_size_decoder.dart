import 'dart:typed_data';

import 'package:fastimage/src/decoders/exif_decoder.dart';
import 'package:fastimage/src/image_size.dart';
import 'package:fastimage/src/decoders/size_decoder.dart';
import 'package:fastimage/src/image_format.dart';
import 'package:fastimage/src/image_orientation.dart';
import 'package:fastimage/src/utils/extensions.dart';

/// TIFF size decoder
///
/// File structure: http://www.fileformat.info/format/tiff/egff.htm
class TiffSizeDecoder implements SizeDecoder {
  ImageFormat get imageFormat => ImageFormat.tiff;
  int get signatureLength => 11;
  int get constantDataLength => null;

  bool supportsFileExtension(String extension) => false;

  bool canDecodeData(Uint8List data) {
    if (data.hasAsciiPrefix("II") || data.hasAsciiPrefix("MM")) {
      final isCRW = data.sublistView(8, 11).hasAsciiPrefix("APC");
      final isCR2 = data.sublistView(8, 11).hasPrefix([0x43, 0x52, 0x02]);
      return !isCRW && !isCR2;
    } else {
      return false;
    }
  }

  ImageSize decode(Uint8List data) {
    final exif = Exif(data);
    if (exif.width == null || exif.height == null)
      return null;

    if (exif.orientation?.isRotated ?? false) {
      return ImageSize(exif.height, exif.width);
    } else {
      return ImageSize(exif.width, exif.height);
    }
  }
}