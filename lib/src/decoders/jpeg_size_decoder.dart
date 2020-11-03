import 'dart:typed_data';

import 'package:fastimage/fastimage.dart';
import 'package:fastimage/src/decoders/exif_decoder.dart';
import 'package:fastimage/src/image_size.dart';
import 'package:fastimage/src/decoders/size_decoder.dart';
import 'package:fastimage/src/image_format.dart';
import 'package:fastimage/src/image_orientation.dart';
import 'package:fastimage/src/utils/extensions.dart';
import 'package:fastimage/src/internal_exceptions.dart';

/// JPEG Size decoder
///
/// File structure: http://www.fileformat.info/format/jpeg/egff.htm
/// JPEG Tags: https://www.sno.phy.queensu.ca/~phil/exiftool/TagNames/JPEG.html
class JpegSizeDecoder implements SizeDecoder {
  ImageFormat get imageFormat => ImageFormat.jpeg;
  int get signatureLength => _signature.length;
  int get constantDataLength => null;

  static const _signature = [0xFF, 0xD8];

  bool supportsFileExtension(String extension) => false;

  bool canDecodeData(Uint8List data) =>
      data.hasPrefix(_signature);

  ImageSize decode(Uint8List data) {
    final blob = ByteData.sublistView(data);
    var searchState = _SearchState.findHeader;
    var offset = 2;
    Exif exif;

    while (offset < data.length) {
      switch (searchState) {
        case _SearchState.findHeader:
          while (blob.getUint8(offset) != 0xFF)
            offset += 1;
          searchState = _SearchState.determineFrameType;
          break;

        case _SearchState.determineFrameType:
          // We've found a data marker, now we determine what type of data we're looking at.
          // FF E0 -> FF EF are 'APPn', and include lots of metadata like EXIF, etc.
          //
          // What we want to find is one of the SOF (Start of Frame) header, cause' it includes
          // width and height (what we want!)
          //
          // JPEG Metadata Header Table
          // http://www.xbdev.net/image_formats/jpeg/tut_jpg/jpeg_file_layout.php
          // Each of these SOF data markers have the same data structure:
          // struct {
          //   UInt16 header; // e.g. FFC0
          //   UInt16 frameLength;
          //   UInt8 samplePrecision;
          //   UInt16 imageHeight;
          //   UInt16 imageWidth;
          //   ... // we only care about this part
          // }
          final sample = blob.getUint8(offset);
          offset += 1;

          // Technically we should check if this has EXIF data here (looking for FFE1 marker)…
          // Maybe TODO later
          if (sample == 0xE1) {
            final exifLength = blob.getUint16(offset, Endian.big);
            final isExif = data.sublistView(offset + 2, offset + 6)
                .hasAsciiPrefix("Exif");
            if (isExif && exif == null) {
              final exifData = data.sublistView(offset + 8);
              try {
                exif = Exif(exifData);
              } catch(e) {
              }
            }
            offset += exifLength;
            searchState = _SearchState.findHeader;
          } else if (sample.isInClosedRange(0xE0, 0xEF)) {
            // Technically we should check if this has EXIF data here (looking for FFE1 marker)…
            searchState = _SearchState.skipFrame;
          } else if (sample.isInClosedRange(0xC0, 0xC3)
              || sample.isInClosedRange(0xC5, 0xC7)
              || sample.isInClosedRange(0xC9, 0xCB)
              || sample.isInClosedRange(0xCD, 0xCF))
          {
            searchState = _SearchState.foundSOF;
          } else if (sample == 0xFF) {
            searchState = _SearchState.determineFrameType;
          } else if (sample == 0xD9) {
            // We made it to the end of the file somehow without finding the size? Likely a corrupt file
            searchState = _SearchState.foundEOI;
          } else {
            // Since we don't handle every header case default to skipping an unknown data marker
            searchState = _SearchState.skipFrame;
          }
          break;

        case _SearchState.skipFrame:
          final frameLength = blob.getUint16(offset, Endian.big);
          offset += frameLength - 1;
          searchState = _SearchState.findHeader;
          break;

        case _SearchState.foundSOF:
          offset += 3;
          var width = blob.getUint16(offset + 2, Endian.big);
          var height = blob.getUint16(offset, Endian.big);

          if (exif?.orientation?.isRotated ?? false) {
            // Rotated
            final temp = width;
            width = height;
            height = temp;
          }

          return ImageSize(width, height);

        case _SearchState.foundEOI:
          throw CorruptedDataException();
      }
    }

    return null;
  }
}

enum _SearchState {
  findHeader,
  determineFrameType,
  skipFrame,
  foundSOF,
  foundEOI,
}

extension on int {
  bool isInClosedRange(int start, int end) => this >= start && this <= end;
}