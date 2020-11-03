import 'dart:typed_data';

import 'package:fastimage/fastimage.dart';

abstract class SizeDecoder {
  ImageFormat get imageFormat;
  int get signatureLength;
  int get constantDataLength;

  bool supportsFileExtension(String extension);
  bool canDecodeData(Uint8List data);
  ImageSize decode(Uint8List data);

  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType;
}