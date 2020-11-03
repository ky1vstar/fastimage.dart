enum ImageOrientation {
  up,
  upMirrored,
  down,
  downMirrored,
  left,
  leftMirrored,
  right,
  rightMirrored,
}

extension ImageOrientationExtension on ImageOrientation {
  bool get isRotated => index >= ImageOrientation.left.index;
}