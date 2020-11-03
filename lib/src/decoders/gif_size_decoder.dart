import 'dart:typed_data';

import 'package:fastimage/src/image_size.dart';
import 'package:fastimage/src/decoders/size_decoder.dart';
import 'package:fastimage/src/image_format.dart';
import 'package:fastimage/src/utils/extensions.dart';

class GifSizeDecoder implements SizeDecoder {
  ImageFormat get imageFormat => ImageFormat.gif;
  int get signatureLength => _signature.length;
  int get constantDataLength => 10;

  static const _signature = [0x47, 0x49];

  bool supportsFileExtension(String extension) =>
      extension == "gif";

  bool canDecodeData(Uint8List data) =>
      data.hasPrefix(_signature);

  ImageSize decode(Uint8List data) {
    if (data.length < constantDataLength)
      return null;

    final blob = ByteData.sublistView(data);
    return ImageSize(
        blob.getUint16(6, Endian.little),
        blob.getUint16(8, Endian.little)
    );
  }
}