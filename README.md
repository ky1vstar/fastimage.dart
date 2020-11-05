# fastimage

[![pub package](https://img.shields.io/pub/v/fastimage.svg?logo=dart&logoColor=00b9fc)](https://pub.dev/packages/fastimage)
[![Dart CI](https://github.com/ky1vstar/fastimage.dart/workflows/Dart%20CI/badge.svg)](https://github.com/ky1vstar/fastimage.dart/actions?query=workflow%3A%22Dart+CI%22)

This is Dart implementation of the excellent Ruby library [FastImage](https://github.com/sdsykes/fastimage).
It allows you to find the size and type of a remote image by downloading as little as possible.

## Supported image types

Currently supported image types are `JPEG`, `PNG`, `GIF`, `TIFF`, `WebP`, `BMP`, `PSD`, `ICO` and `CUR`.

## Usage

To use this package, add `fastimage` as a [dependency in your pubspec.yaml file](https://flutter.dev/docs/development/packages-and-plugins/using-packages).

### Example

Usage of `fastimage` is pretty straightforward.

```dart
import 'package:fastimage/fastimage.dart';

...

final response = await FastImage.shared().getSize("http://i.imgur.com/7GLI90s.jpg");
// or
final fastImage = FastImage();
final response = await fastImage.getSize("http://i.imgur.com/7GLI90s.jpg");
fastImage.close(); // non-shared instances of FastImage should be closed

print(response)
// Prints: `GetSizeResponse(size: ImageSize(width: 1600, height: 1200), format: ImageFormat.jpeg)`
```

## To Do

* Provide documentation
* Provide example

## Thanks & Credits

* [sdsykes](https://github.com/sdsykes)'s [FastImage](https://github.com/sdsykes/fastimage) for inspiration and test resources
* [kylehickinson](https://github.com/kylehickinson)'s [FastImage](https://github.com/kylehickinson/FastImage) for some source codes
