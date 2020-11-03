import 'package:fastimage/src/image_size.dart';
import 'package:fastimage/src/image_format.dart';
import 'package:fastimage/src/utils/hasher.dart';

class GetSizeResponse {
  final ImageSize size;
  final ImageFormat format;

  GetSizeResponse(int width, int height, this.format)
      : assert(format != null),
        size = ImageSize(width, height);

  GetSizeResponse.size(this.size, this.format)
      : assert(size != null),
        assert(format != null);

  @override
  String toString() =>
      "GetSizeResponse(size: $size, format: $format)";

  @override
  bool operator ==(o) => o is GetSizeResponse
      && size == o.size
      && format == o.format;

  @override
  int get hashCode => Hasher()
      .combine(size)
      .combine(format)
      .finalize();
}