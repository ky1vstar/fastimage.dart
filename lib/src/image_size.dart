import 'package:fastimage/src/utils/hasher.dart';

class ImageSize {
  final int width;
  final int height;

  const ImageSize(this.width, this.height);

  @override
  String toString() =>
      "ImageSize(width: $width, height: $height)";

  @override
  bool operator ==(o) => o is ImageSize
      && width == o.width
      && height == o.height;

  @override
  int get hashCode => Hasher()
      .combine(width)
      .combine(height)
      .finalize();
}