import 'dart:io';

import 'package:test/test.dart';
import 'package:fastimage/fastimage.dart';

// \[:(.+), \[(\d+), ?(\d+)\]\]
// GetSizeResponse($2, $3, ImageFormat.$1)
final goodFixtures = {
  "test.bmp": GetSizeResponse(40, 27, ImageFormat.bmp),
  "test2.bmp": GetSizeResponse(1920, 1080, ImageFormat.bmp),
  "test_coreheader.bmp": GetSizeResponse(40, 27, ImageFormat.bmp),
  "test_v5header.bmp": GetSizeResponse(40, 27, ImageFormat.bmp),
  "test.gif": GetSizeResponse(17, 32, ImageFormat.gif),
  "animated.gif": GetSizeResponse(400, 400, ImageFormat.gif),
  "test.jpg": GetSizeResponse(882, 470, ImageFormat.jpeg),
  "test.png": GetSizeResponse(30, 20, ImageFormat.png),
  "test2.jpg": GetSizeResponse(250, 188, ImageFormat.jpeg),
  "test3.jpg": GetSizeResponse(630, 367, ImageFormat.jpeg),
  "test4.jpg": GetSizeResponse(1485, 1299, ImageFormat.jpeg),
  "test.tiff": GetSizeResponse(85, 67, ImageFormat.tiff),
  "test2.tiff": GetSizeResponse(333, 225, ImageFormat.tiff),
  "test.psd": GetSizeResponse(17, 32, ImageFormat.psd),
  "exif_orientation.jpg": GetSizeResponse(600, 450, ImageFormat.jpeg),
  "infinite.jpg": GetSizeResponse(160, 240, ImageFormat.jpeg),
  "orient_2.jpg": GetSizeResponse(230, 408, ImageFormat.jpeg),
  "favicon.ico":  GetSizeResponse(16, 16, ImageFormat.ico),
  "favicon2.ico":  GetSizeResponse(32, 32, ImageFormat.ico),
  "man.ico":  GetSizeResponse(256, 256, ImageFormat.ico),
  "test.cur":  GetSizeResponse(32, 32, ImageFormat.cur),
  "webp_vp8x.webp":  GetSizeResponse(386, 395, ImageFormat.webp),
  "webp_vp8l.webp":  GetSizeResponse(386, 395, ImageFormat.webp),
  "webp_vp8.webp":  GetSizeResponse(550, 368, ImageFormat.webp),
//  "test.svg":  GetSizeResponse(200, 300, ImageFormat.svg),
//  "test_partial_viewport.svg":  GetSizeResponse(860, 400, ImageFormat.svg),
//  "test2.svg":  GetSizeResponse(366, 271, ImageFormat.svg),
//  "test3.svg":  GetSizeResponse(255, 48, ImageFormat.svg),
//  "test4.svg":  GetSizeResponse(271, 271, ImageFormat.svg),
  "orient_6.jpg": GetSizeResponse(1250, 2500, ImageFormat.jpeg),
  "wrong_extension_png.bmp": GetSizeResponse(30, 20, ImageFormat.png),
};

const badFixtures = [
  "faulty.jpg",
  "test_rgb.ct",
  "test.xml",
  "test2.xml",
  "a.CR2",
  "a.CRW"
];

const exifDirectories = [
  "jpg", "tiff-ccitt-rle", "tiff-ccitt4", "tiff-jpeg6", "tiff-jpeg7",
  "tiff-lzw-bw", "tiff-lzw-color", "tiff-packbits-color",
];

final fastImage = FastImage();
const fixturesUrl = "https://raw.githubusercontent.com/ky1vstar/fastimage.dart/master/test/fixtures/";
final fixturesPath = Directory.current.path + "/test/fixtures/";
final unsupporedMatch = throwsA(isA<UnsupportedImageFormatException>());

void main() {
  if (Platform.environment["PROXY"] == "1") {
    fastImage.client.findProxy = (uri) {
      return "PROXY localhost:27016";
    };
    fastImage.client.badCertificateCallback = (cert, host, port) {
      return true;
    };
  }

  test("data url", () {
    final url = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAIAAAABCAYAAAD0In+KAAAAD0lEQVR42mNk+M9QzwAEAAmGAYCF+yOnAAAAAElFTkSuQmCC";
    expect(
        fastImage.getSize(url),
        completion(GetSizeResponse(2, 1, ImageFormat.png))
    );
  });

  test("remote bunch", () {
    final future = Future.wait(goodFixtures.keys.map(
            (e) => fastImage.getSize(fixturesUrl + e)
    ));
    expect(
        future,
        completion(goodFixtures.values)
    );
  });

  group("remote good fixtures", () {
    goodFixtures.forEach((key, value) {
      testRemoteFixture(key, key, value);
    });
  });

  group("remote bad fixtures", () {
    badFixtures.forEach((path) {
      testRemoteFixture(path, path, unsupporedMatch);
    });
  });

  test("local bunch", () {
    final future = Future.wait(goodFixtures.keys.map(
            (e) => fastImage.getSize(fixturesPath + e)
    ));
    expect(
        future,
        completion(goodFixtures.values)
    );
  });

  group("local good fixtures", () {
    goodFixtures.forEach((key, value) {
      testLocalFixture(key, key, value);
    });
  });

  group("local bad fixtures", () {
    badFixtures.forEach((path) {
      testLocalFixture(path, path, unsupporedMatch);
    });
  });

  testRemoteFixture(
      "wrong url",
      "does_not_exist",
      throwsException
  );

  testLocalFixture(
      "local files with path that has spaces",
      "folder with spaces/test.bmp",
      GetSizeResponse(40, 27, ImageFormat.bmp)
  );

  group("exif orientation", () {
    for (final d in exifDirectories) {
      for (var i = 1; i <= 8; i++) {
        final url = "${fixturesUrl}exif-orientation-testimages/$d/ExifOrientation$i.${d == "jpg" ? "jpg" : "tif"}";
        test("$d $i", () {
          expect(
              fastImage.getSize(url).then((value) => value.size),
              completion(ImageSize(1240, 1754))
          );
        });
      }
    }
  });

  group("cannon raw formats are not recognised as tiff", () {
    ["a.CR2", "a.CRW",].forEach((element) =>
        testRemoteFixture(element, element, unsupporedMatch)
    );
  });
}

void testRemoteFixture(description, String path, matcher) {
  test(description, () {
    expect(
        fastImage.getSize(fixturesUrl + path),
        anyOf(matcher, completion(matcher))
    );
  });
}

void testLocalFixture(description, String path, matcher) {
  test(description, () {
    expect(
        fastImage.getSize(fixturesPath + path),
        anyOf(matcher, completion(matcher))
    );
  });
}
