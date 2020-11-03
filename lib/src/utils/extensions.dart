import 'dart:convert';
import 'dart:core';

import 'dart:typed_data';

extension UriExtension on Uri {
  String get pathExtension => data == null
      ? pathSegments.last?.split(".")?.last?.toLowerCase()
      : null;

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

extension ListIntExtension on List<int> {
  bool hasAsciiPrefix(String prefix) =>
      hasPrefix(ascii.encode(prefix));
}

extension Uint8ListExtension on Uint8List {
  Uint8List sublistView(int start, [int end]) =>
      Uint8List.sublistView(this, start, end);
}