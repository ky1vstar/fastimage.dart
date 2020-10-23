import 'package:fastimage/src/image_format.dart';
import 'package:fastimage/src/utils/hasher.dart';

class GetSizeResponse {
  final int width;
  final int height;
  final ImageFormat format;

  const GetSizeResponse(this.width, this.height, this.format);

  @override
  String toString() =>
      "GetSizeResponse(width: $width, height: $height, format: $format)";

  @override
  bool operator ==(o) => o is GetSizeResponse
      && width == o.width
      && height == o.height
      && format == o.format;

  @override
  int get hashCode => Hasher()
      .combine(width)
      .combine(height)
      .combine(format)
      .finalize();
}