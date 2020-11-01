import 'dart:io';
import 'dart:async';

import 'package:fastimage/src/get_size_response.dart';
import 'package:fastimage/src/get_size_operation.dart';
import 'package:fastimage/src/internal_exceptions.dart';
import 'package:fastimage/src/utils/extensions.dart';

import 'package:fastimage/src/decoders/size_decoder.dart';
import 'package:fastimage/src/decoders/bmp_size_decoder.dart';
import 'package:fastimage/src/decoders/gif_size_decoder.dart';
import 'package:fastimage/src/decoders/psd_size_decoder.dart';
import 'package:fastimage/src/decoders/png_size_decoder.dart';
import 'package:fastimage/src/decoders/jpeg_size_decoder.dart';

class FastImage {
  static FastImage _instance;

  final HttpClient client;
  final List<SizeDecoder> _decoders = [
    PngSizeDecoder(),
    GifSizeDecoder(),
    BmpSizeDecoder(),
    PsdSizeDecoder(),
    JpegSizeDecoder(),
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
    return _getSizeUri(uri, headers, true);
  }

  void close() {
    if (this != _instance) {
      client.close(force: true);
    }
  }

  Future<GetSizeResponse> _getSizeUri(
      Uri uri, Map<String, String> headers, bool shouldResolveDecoderByExtension
  ) async {
    try {
      final operation = GetSizeOperation(
          uri,
          _decoders,
          shouldResolveDecoderByExtension
              ? _decoderForExtension(uri.pathExtension)
              : null
      );
      return await operation.start(client, headers);
    } on DecoderTypeMismatchException catch(_) {
      if (!shouldResolveDecoderByExtension)
        rethrow;
      return _getSizeUri(uri, headers, false);
    }
  }

  SizeDecoder _decoderForExtension(String extension) {
    if (extension == null)
      return null;
    return _decoders.firstWhere(
            ($0) => $0.supportsFileExtension(extension)
                && $0.constantDataLength != null,
        orElse: () => null
    );
  }
}