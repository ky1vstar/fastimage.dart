import 'dart:io';
import 'dart:async';

import 'package:fastimage/src/decoders/gif_size_decoder.dart';
import 'package:fastimage/src/get_size_response.dart';
import 'package:fastimage/src/decoders/png_size_decoder.dart';
import 'package:fastimage/src/get_size_operation.dart';
import 'package:fastimage/src/decoders/size_decoder.dart';

class FastImage {
  static FastImage _instance;

  final HttpClient client;
  final List<SizeDecoder> _decoders = [
    PngSizeDecoder(),
    GifSizeDecoder(),
  ];

  FastImage([HttpClient client])
    : this.client = client ?? HttpClient();

  factory FastImage.shared() {
    if (_instance == null)
      _instance = FastImage();
    return _instance;
  }

  Future<GetSizeResponse> getSize(String url, {Map<String, String> headers}) {
    final uri = Uri.parse(url);
    return getSizeUri(uri, headers: headers);
  }

  Future<GetSizeResponse> getSizeUri(Uri uri, {Map<String, String> headers}) {
    final operation = GetSizeOperation(_decoders, uri);
    return operation.start(client, headers);
  }

  void close() {
    if (this != _instance) {
      client.close(force: true);
    }
  }
}