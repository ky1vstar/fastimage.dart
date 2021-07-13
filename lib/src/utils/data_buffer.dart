import 'dart:typed_data';

class DataBuffer {
  Uint8List get byteList => Uint8List.sublistView(_bytes, 0, _length);
  int get length => _length;

  static const _initialBufferSize = 1024;
  int? _maxLength;
  Uint8List _bytes;
  int _length = 0;

  DataBuffer({int? maxLength})
      : assert(maxLength == null || maxLength > 0),
        _maxLength = maxLength,
        _bytes = maxLength != null
            ? Uint8List(maxLength) : Uint8List(_initialBufferSize);

  void add(Iterable<int> chunk) {
    if (_maxLength != null) {
      final slice = chunk.take(_bytes.length - _length);
      _bytes.setAll(length, slice);
      _length += slice.length;
      return;
    }

    final freeLength = _bytes.length - _length;
    if (chunk.length > freeLength) {
      // Grow the buffer.
      var oldLength = _bytes.length;
      var newLength = _roundToPowerOf2(chunk.length + oldLength) * 2;
      var grown = Uint8List(newLength);
      grown.setRange(0, _bytes.length, _bytes);
      _bytes = grown;
    }
    _bytes.setAll(length, chunk);
    _length += chunk.length;
  }

  static int _roundToPowerOf2(int v) {
    assert(v > 0);
    v--;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;
    v++;
    return v;
  }
}