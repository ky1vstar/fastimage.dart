import 'dart:io';

import 'package:test/test.dart';
import 'package:fastimage/fastimage.dart';

// \[:(.+), \[(\d+), ?(\d+)\]\]
// GetSizeResponse($2, $3, ImageFormat.$1)
final GoodFixtures = {
  "test.bmp": GetSizeResponse(40, 27, ImageFormat.bmp),
  "test2.bmp": GetSizeResponse(1920, 1080, ImageFormat.bmp),
  "test_coreheader.bmp": GetSizeResponse(40, 27, ImageFormat.bmp),
  "test_v5header.bmp": GetSizeResponse(40, 27, ImageFormat.bmp),
  "test.gif": GetSizeResponse(17, 32, ImageFormat.gif),
  "animated.gif": GetSizeResponse(400, 400, ImageFormat.gif),
//  "test.jpg": GetSizeResponse(882, 470, ImageFormat.jpeg),
  "test.png": GetSizeResponse(30, 20, ImageFormat.png),
//  "test2.jpg": GetSizeResponse(250, 188, ImageFormat.jpeg),
//  "test3.jpg": GetSizeResponse(630, 367, ImageFormat.jpeg),
//  "test4.jpg": GetSizeResponse(1485, 1299, ImageFormat.jpeg),
//  "test.tiff": GetSizeResponse(85, 67, ImageFormat.tiff),
//  "test2.tiff": GetSizeResponse(333, 225, ImageFormat.tiff),
  "test.psd": GetSizeResponse(17, 32, ImageFormat.psd),
//  "exif_orientation.jpg": GetSizeResponse(600, 450, ImageFormat.jpeg),
//  "infinite.jpg": GetSizeResponse(160, 240, ImageFormat.jpeg),
//  "orient_2.jpg": GetSizeResponse(230, 408, ImageFormat.jpeg),
//  "favicon.ico":  GetSizeResponse(16, 16, ImageFormat.ico),
//  "favicon2.ico":  GetSizeResponse(32, 32, ImageFormat.ico),
//  "man.ico":  GetSizeResponse(256, 256, ImageFormat.ico),
//  "test.cur":  GetSizeResponse(32, 32, ImageFormat.cur),
//  "webp_vp8x.webp":  GetSizeResponse(386, 395, ImageFormat.webp),
//  "webp_vp8l.webp":  GetSizeResponse(386, 395, ImageFormat.webp),
//  "webp_vp8.webp":  GetSizeResponse(550, 368, ImageFormat.webp),
//  "test.svg":  GetSizeResponse(200, 300, ImageFormat.svg),
//  "test_partial_viewport.svg":  GetSizeResponse(860, 400, ImageFormat.svg),
//  "test2.svg":  GetSizeResponse(366, 271, ImageFormat.svg),
//  "test3.svg":  GetSizeResponse(255, 48, ImageFormat.svg),
//  "test4.svg":  GetSizeResponse(271, 271, ImageFormat.svg),
//  "orient_6.jpg": GetSizeResponse(1250, 2500, ImageFormat.jpeg)
};

final BadFixtures = [
  "faulty.jpg",
  "test_rgb.ct",
  "test.xml",
  "test2.xml",
  "a.CR2",
  "a.CRW"
];

void main() {
  test('adds one to input values', () async {
    print(Directory.current);

    final fastImage = FastImage();
    if (Platform.environment["PROXY"] == "1") {
      fastImage.client.findProxy = (uri) {
        return "PROXY localhost:27016";
      };
      fastImage.client.badCertificateCallback = (cert, host, port) {
        return true;
      };
    }


    var result = await fastImage.getSize("https://flutter.dev/assets/flutter-lockup-1caf6476beed76adec3c477586da54de6b552b2f42108ec5bc68dc63bae2df75.png");
    print(result);
    expect(result.format, ImageFormat.png);

    result = await fastImage.getSize("https://github.com/ky1vstar/PiPhone/blob/master/Demonstration/PiPhone.gif?raw=true");
    print(result);
    expect(result.format, ImageFormat.gif);

    result = await fastImage.getSize("https://github.com/ky1vstar/tdjson/releases/download/1.4.0/credit-card-template.psd");
    print(result);
    expect(result.format, ImageFormat.psd);
//    print(response);
//    expect(calculator.addOne(2), 3);
//    expect(calculator.addOne(-7), -6);
//    expect(calculator.addOne(0), 1);
//    expect(() :  calculator.addOne(null), throwsNoSuchMethodError);
  });
}
