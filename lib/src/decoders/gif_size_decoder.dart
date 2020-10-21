import 'dart:typed_data';

import 'package:fastimage/src/get_size_response.dart';
import 'package:fastimage/src/decoders/size_decoder.dart';
import 'package:fastimage/src/image_format.dart';

class GifSizeDecoder implements SizeDecoder {
  int get signatureLength => _signature.length;
  final int constantDataLength = 10;

  static const _signature = [0x47, 0x49];

  bool supportsFileExtenstion(String extension) =>
      extension == "gif";

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
        blob.getUint16(6, Endian.little),
        blob.getUint16(8, Endian.little),
        ImageFormat.gif
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