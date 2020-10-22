import 'dart:typed_data';

import 'package:fastimage/src/get_size_response.dart';

abstract class SizeDecoder {
  int get signatureLength;
  int get constantDataLength;

  bool supportsFileExtenstion(String extension);
  bool canDecodeData(Uint8List data);
  GetSizeResponse decode(Uint8List data);
}