import 'dart:async';
import 'dart:io';
import 'dart:core';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:fastimage/src/internal_exceptions.dart';
import 'package:fastimage/src/public_exceptions.dart';
import 'package:fastimage/src/utils/compute.dart';
import 'package:fastimage/src/utils/data_buffer.dart';
import 'package:fastimage/src/utils/extensions.dart';
import 'package:fastimage/src/utils/compute_stream.dart';
import 'package:fastimage/src/get_size_response.dart';
import 'package:fastimage/src/decoders/size_decoder.dart';

class GetSizeOperation {
  final Uri uri;
  final List<SizeDecoder> decoders;
  final SizeDecoder? preferredDecoder;

  GetSizeOperation(this.uri, this.decoders, this.preferredDecoder);

  Future<GetSizeResponse> start(
      HttpClient client, Map<String, String>? headers
  ) {
    if (uri.isFileUri) {
      if (preferredDecoder?.constantDataLength == null) {
        // start isolate only if we are going to work with non-constant amount of data
        return compute(_computeLocalFile, this);
      } else {
        return _startLocalFile();
      }
    } else if (uri.data != null) {
      return compute(_computeDataUri, this);
    } else {
      return _startRemote(client, headers);
    }
  }

  Future<GetSizeResponse> _startRemote(
      HttpClient client, Map<String, String>? headers
  ) async {
    final request = await client.getUrl(uri);
    headers?.forEach((name, value) => request.headers.add(name, value));
    final constantDataLength = preferredDecoder?.constantDataLength;
    if (constantDataLength != null) {
      request.headers
        ..removeAll(HttpHeaders.acceptEncodingHeader)
        ..set("Range", "bytes=0-${constantDataLength - 1}");
    }

    final response = await request.close();
    if (response.statusCode < HttpStatus.ok
        || response.statusCode >= HttpStatus.multipleChoices) {
      throw WrongStatusCodeException(
          statusCode: response.statusCode, uri: uri
      );
    }

    if (constantDataLength != null) {
      return _handleResponse(response);
    } else {
      // start isolate only if we are going to work with non-constant amount of data
      return computeStream(_computeRemote, response, this);
    }
  }

  Future<GetSizeResponse> _startDataUri() {
    late StreamController<List<int>> controller;
    controller = StreamController<List<int>>(onListen: () =>
        controller.add(uri.data!.contentAsBytes()));
    return _handleResponse(controller.stream)
        .whenComplete(() => controller.close());
  }

  Future<GetSizeResponse> _startLocalFile() {
    final file = File(uri.toFilePath());
    final dataStream = file.openRead(0, preferredDecoder?.constantDataLength);
    return _handleResponse(dataStream);
  }

  Future<GetSizeResponse> _handleResponse(Stream<List<int>> dataStream) {
    final completer = Completer<GetSizeResponse>.sync();
    final maxSignatureLength = decoders.fold<int>(0, (previousValue, element) =>
        max(previousValue, element.signatureLength));
    final buffer = DataBuffer(maxLength: preferredDecoder?.constantDataLength);
    SizeDecoder? resolvedDecoder;
    late StreamSubscription<List<int>> subscription;

    subscription = dataStream.listen(
        (chunk) {
          if (completer.isCompleted)
            return;

          buffer.add(chunk);
          resolvedDecoder ??= _decoderForData(buffer.byteList);

          if (resolvedDecoder == null) {
            if (buffer.length > maxSignatureLength) {
              completer.completeError(UnsupportedImageFormatException(
                  uri: uri
              ));
              subscription.cancel();
            }
            return;
          }

          if (preferredDecoder != null
              && preferredDecoder != resolvedDecoder) {
            completer.completeError(DecoderTypeMismatchException());
            subscription.cancel();
            return;
          }

          GetSizeResponse? result;
          try {
            result = GetSizeResponse.size(
                resolvedDecoder!.decode(buffer.byteList)!,
                resolvedDecoder!.imageFormat
            );
          } on CorruptedDataException catch(_) {
            completer.completeError(CorruptedImageFormatException(
                format: resolvedDecoder!.imageFormat, uri: uri
            ));
            subscription.cancel();
            return;
          } catch(_) {
            // do nothing
          }

          if (result != null) {
            completer.complete(result);
          } else if (resolvedDecoder!.constantDataLength != null
              && buffer.length > resolvedDecoder!.constantDataLength!)
          {
            completer.completeError(CorruptedImageFormatException(
                format: resolvedDecoder!.imageFormat, uri: uri
            ));
            subscription.cancel();
          }
        },
        onDone: () {
          if (!completer.isCompleted)
            completer.completeError(UnsupportedImageFormatException(uri: uri));
        },
        onError: completer.completeError,
        cancelOnError: true
    );

    return completer.future;
  }

  SizeDecoder? _decoderForData(Uint8List data) =>
      decoders.firstWhereOrNull(($0) => $0.canDecodeData(data));
}

Future<GetSizeResponse> _computeRemote(
  Stream<List<int>> dataStream, GetSizeOperation operation
) {
  return operation._handleResponse(dataStream);
}

Future<GetSizeResponse> _computeLocalFile(GetSizeOperation operation) {
  return operation._startLocalFile();
}

Future<GetSizeResponse> _computeDataUri(GetSizeOperation operation) {
  return operation._startDataUri();
}
