import 'dart:core';

extension UriExtension on Uri {
  String get pathExtension =>
      pathSegments.last?.split(".")?.last?.toLowerCase();

  bool get isFileUri {
    try {
      toFilePath();
      return true;
    } catch(e) {
      return false;
    }
  }
}

extension IterableExtension<E> on Iterable<E> {
  bool hasPrefix(Iterable<E> prefix) {
    if (length < prefix.length)
      return false;

    for (var i = 0; i < prefix.length; i++)
      if (this.elementAt(i) != prefix.elementAt(i))
        return false;

    return true;
  }
}