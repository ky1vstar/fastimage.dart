import 'dart:typed_data';

import 'package:fastimage/src/image_size.dart';
import 'package:fastimage/src/decoders/size_decoder.dart';
import 'package:fastimage/src/image_format.dart';
import 'package:fastimage/src/utils/extensions.dart';

class PngSizeDecoder implements SizeDecoder {
  ImageFormat get imageFormat => ImageFormat.png;
  int get signatureLength => _signature.length;
  int get constantDataLength => 24;

  static const _signature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

  bool supportsFileExtension(String extension) =>
    extension == "png";

  bool canDecodeData(Uint8List data) =>
    data.hasPrefix(_signature);

  ImageSize? decode(Uint8List data) {
    if (data.length < constantDataLength)
      return null;

    final blob = ByteData.sublistView(data);
    return ImageSize(
        blob.getUint32(16, Endian.big),
        blob.getUint32(20, Endian.big)
    );
  }
}