import 'dart:core';

extension UriPathExtension on Uri {
  String get pathExtension =>
      pathSegments.last?.split(".")?.last?.toLowerCase();
}