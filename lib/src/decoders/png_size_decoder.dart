import 'dart:typed_data';

import 'package:fastimage/src/get_size_response.dart';
import 'package:fastimage/src/decoders/size_decoder.dart';
import 'package:fastimage/src/image_format.dart';

class PngSizeDecoder implements SizeDecoder {
  int get signatureLength => _signature.length;
  final int constantDataLength = 24;

  static const _signature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

  bool supportsFileExtenstion(String extension) =>
    extension == "png";

  bool canDecodeData(List<int> data) {
    if (data.length < signatureLength) {
      return false;
    } else {
      final slice = data.getRange(0, signatureLength);
      return _listsAreEqual(slice, _signature);
    }
  }

  GetSizeResponse decode(List<int> data) {
    if (data.length < constantDataLength)
      return null;

    final blob = ByteData.sublistView(Uint8List.fromList(data));
    return GetSizeResponse(
        blob.getUint32(16, Endian.big),
        blob.getUint32(20, Endian.big),
        ImageFormat.png
    );
  }
}

bool _listsAreEqual(list1, list2) {
  var i=-1;
  return list1.every((val) {
    i++;
    if(val is List && list2[i] is List) return _listsAreEqual(val,list2[i]);
    else return list2[i] == val;
  });
}