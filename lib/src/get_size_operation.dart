import 'dart:async';
import 'dart:io';
import 'dart:core';
import 'dart:typed_data';

import 'package:fastimage/src/utils/extensions.dart';
import 'package:fastimage/src/utils/compute_stream.dart';
import 'package:fastimage/src/get_size_response.dart';
import 'package:fastimage/src/decoders/size_decoder.dart';

class GetSizeOperation {
  final List<SizeDecoder> decoders;
  final Uri url;

  GetSizeOperation(this.decoders, this.url);

  Future<GetSizeResponse> start(
      HttpClient client, Map<String, String> headers
  ) async {
    final request = await client.getUrl(url);
    headers?.forEach((name, value) => request.headers.add(name, value));
    final constantDataLength = _decoderForExtension(url.pathExtension)
        ?.constantDataLength;
    if (constantDataLength != null) {
      request.headers
        ..removeAll(HttpHeaders.acceptEncodingHeader)
        ..set("Range", "bytes=0-${constantDataLength - 1}");
    }

    final response = await request.close();
    if (response.statusCode < HttpStatus.ok
        || response.statusCode >= HttpStatus.multipleChoices) {
      throw "Wrong status code"; // TODO
    }

    if (constantDataLength != null) {
      return _handleResponse(response);
    } else {
      return computeStream(_compute, response, this);
    }
  }

  Future<GetSizeResponse> _handleResponse(Stream<List<int>> responseStream) {
    final completer = Completer<GetSizeResponse>.sync();
    final maxSignatureLength = decoders.fold(0, (previousValue, element) =>
    previousValue + element.signatureLength);
    final data = List<int>();
    SizeDecoder resolvedDecoder;
    StreamSubscription<List<int>> subscription;

    subscription = responseStream.listen(
        (chunk) {
          if (completer.isCompleted)
            return;

          data.addAll(chunk);
          resolvedDecoder ??= _decoderForData(data);

          if (resolvedDecoder != null) {
            final result = resolvedDecoder.decode(data);
            if (result != null) {
              completer.complete(result);
            } else if (resolvedDecoder.constantDataLength != null
                && data.length > resolvedDecoder.constantDataLength)
            {
              completer.completeError("Wrong type #1");
              subscription.cancel();
            }
          } else if (data.length > maxSignatureLength) {
            completer.completeError("Wrong type #2");
            subscription.cancel();
          }
        },
        onDone: () {
          if (!completer.isCompleted)
            completer.completeError("Wrong type #3");
        },
        onError: completer.completeError,
        cancelOnError: true
    );

    return completer.future;
  }

  SizeDecoder _decoderForExtension(String extension) {
    if (extension == null)
      return null;
    return decoders.firstWhere(
        ($0) => $0.supportsFileExtenstion(extension),
        orElse: () => null
    );
  }

  SizeDecoder _decoderForData(List<int> data) =>
      decoders.firstWhere(($0) => $0.canDecodeData(data), orElse: () => null);
}

Future<GetSizeResponse> _compute(
  Stream<List<int>> responseStream, GetSizeOperation operation
) {
  return operation._handleResponse(responseStream);
}