import 'dart:io';

import 'package:test/test.dart';
import 'package:fastimage/fastimage.dart';

void main() {
  test('adds one to input values', () async {
    final fastImage = FastImage();
    if (Platform.environment["PROXY"] == "1") {
      fastImage.client.findProxy = (uri) {
        return "PROXY localhost:27016";
      };
      fastImage.client.badCertificateCallback = (cert, host, port){
        return true;
      };
    }

    var result = await fastImage.getSize("https://flutter.dev/assets/flutter-lockup-1caf6476beed76adec3c477586da54de6b552b2f42108ec5bc68dc63bae2df75.png");
    print(result);
    expect(result.format, ImageFormat.png);

    result = await fastImage.getSize("https://github.com/ky1vstar/PiPhone/blob/master/Demonstration/PiPhone.gif?raw=true");
    print(result);
    expect(result.format, ImageFormat.gif);
//    print(response);
//    expect(calculator.addOne(2), 3);
//    expect(calculator.addOne(-7), -6);
//    expect(calculator.addOne(0), 1);
//    expect(() => calculator.addOne(null), throwsNoSuchMethodError);
  });
}
