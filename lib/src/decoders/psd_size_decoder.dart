import 'dart:typed_data';

import 'package:fastimage/src/image_size.dart';
import 'package:fastimage/src/decoders/size_decoder.dart';
import 'package:fastimage/src/image_format.dart';
import 'package:fastimage/src/utils/extensions.dart';

class PsdSizeDecoder implements SizeDecoder {
  ImageFormat get imageFormat => ImageFormat.psd;
  int get signatureLength => _signature.length;
  int get constantDataLength => 22;

  static const _signature = [0x38, 0x42];

  bool supportsFileExtension(String extension) =>
      extension == "psd";

  bool canDecodeData(Uint8List data) =>
      data.hasPrefix(_signature);

  ImageSize? decode(Uint8List data) {
    if (data.length < constantDataLength)
      return null;

    final blob = ByteData.sublistView(data);
    return ImageSize(
        blob.getUint32(18, Endian.big),
        blob.getUint32(14, Endian.big)
    );
  }
}