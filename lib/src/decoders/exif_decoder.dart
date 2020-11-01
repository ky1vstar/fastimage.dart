import 'dart:typed_data';

import 'package:fastimage/src/image_orientation.dart';
import 'package:fastimage/src/utils/extensions.dart';

/// Obtains the image width, height and orientation from an EXIF data structure
///
/// Can also be used for EXIF JPEG's, but will only find orientation data
/// (among other Exif tags we dont care about)
///
/// http://www.fileformat.info/format/tiff/egff.htm
class Exif {
  final ImageOrientation orientation;
  final int width;
  final int height;

  const Exif._(this.orientation, this.width, this.height);

  factory Exif(Uint8List data) {
    final blob = ByteData.sublistView(data);
    ImageOrientation orientation;
    int width;
    int height;

    // Little endian defined as "II", big endian defined as "MM"
    final endian = data.hasPrefix([0x49, 0x49]) ? Endian.little : Endian.big;
    var offset = blob.getInt32(4, endian);
    final numberOfTags = blob.getInt16(offset, endian);
    offset += 2;

    for (var i = 0; i < numberOfTags; i++) {
      final tagIdentifier = blob.getInt16(offset, endian);
      final value = blob.getInt16(offset + 8, endian);
      switch (tagIdentifier) {
        case 0x0100:
          width = value;
          break;
        case 0x0101:
          height = value;
          break;
        case 0x0112:
          orientation = ImageOrientation.values[value];
          break;
      }

      if (orientation != null && width != null && height != null)
        break;
      // Each tag is 12 bytes long
      offset += 12;
    }

    return Exif._(orientation, width, height);
  }
}