import 'dart:typed_data';

import 'package:fastimage/src/decoders/ico_size_decoder.dart';
import 'package:fastimage/src/decoders/size_decoder.dart';
import 'package:fastimage/src/image_format.dart';
import 'package:fastimage/src/utils/extensions.dart';
import 'package:fastimage/src/image_size.dart';

/// CUR size decoder
///
/// File structure: https://en.wikipedia.org/wiki/ICO_(file_format)#Outline
class CurSizeDecoder implements SizeDecoder {
  ImageFormat get imageFormat => ImageFormat.cur;
  int get signatureLength => _signature.length;
  int get constantDataLength => null;

  static const _signature = [0x00, 0x00, 0x02];

  bool supportsFileExtension(String extension) => false;

  bool canDecodeData(Uint8List data) =>
      data.hasPrefix(_signature);

  ImageSize decode(Uint8List data) => IcoSizeDecoder.decodeSize(data);
}