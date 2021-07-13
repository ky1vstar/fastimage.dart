import 'dart:typed_data';

import 'package:fastimage/src/image_size.dart';
import 'package:fastimage/src/decoders/size_decoder.dart';
import 'package:fastimage/src/image_format.dart';
import 'package:fastimage/src/utils/extensions.dart';

class BmpSizeDecoder implements SizeDecoder {
  ImageFormat get imageFormat => ImageFormat.bmp;
  int get signatureLength => _signature.length;
  int get constantDataLength => 26;

  static const _signature = [0x42, 0x4D];

  bool supportsFileExtension(String extension) =>
      extension == "bmp";

  bool canDecodeData(Uint8List data) =>
      data.hasPrefix(_signature);

  ImageSize? decode(Uint8List data) {
    if (data.length < constantDataLength)
      return null;

    final blob = ByteData.sublistView(data);
    if (blob.getUint8(14) == 12) {
      return ImageSize(
          blob.getUint16(18, Endian.little),
          blob.getUint16(20, Endian.little)
      );
    } else {
      return ImageSize(
          blob.getInt32(18, Endian.little),
          blob.getInt32(22, Endian.little).abs()
      );
    }
  }
}