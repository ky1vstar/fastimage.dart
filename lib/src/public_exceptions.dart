import 'package:fastimage/fastimage.dart';

abstract class FastImageException implements Exception {}

/// The exception thrown when the HTTP request to load a network image fails.
class WrongStatusCodeException implements FastImageException {
  /// Creates a [FastImageWrongStatusCodeException] with the specified
  /// http [statusCode] and [uri].
  WrongStatusCodeException({
    required this.statusCode, required this.uri
  })
      : _message = "HTTP request failed, statusCode: $statusCode, $uri";

  /// The HTTP status code from the server.
  final int statusCode;

  /// A human-readable error message.
  final String _message;

  /// Resolved URL of the requested image.
  final Uri uri;

  @override
  String toString() => _message;
}

class CorruptedImageFormatException implements FastImageException {
  CorruptedImageFormatException({
    required this.format, required this.uri
  })
      : _message = "Failed to decode image with type $format, $uri";

  final ImageFormat format;

  final String _message;

  final Uri uri;

  @override
  String toString() => _message;
}

class UnsupportedImageFormatException implements FastImageException {
  UnsupportedImageFormatException({
    required this.uri
  })
      : _message = "Unsupported image format $uri";

  final String _message;

  final Uri uri;

  @override
  String toString() => _message;
}