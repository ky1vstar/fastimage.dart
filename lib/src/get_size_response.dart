import 'image_format.dart';

class GetSizeResponse {
  final int width;
  final int height;
  final ImageFormat format;

  GetSizeResponse(this.width, this.height, this.format);

  @override
  String toString() =>
      "GetSizeResponse(width: $width, height: $height, format: $format)";
}