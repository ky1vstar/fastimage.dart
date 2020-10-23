class Hasher {
  var _hash = 0;

  Hasher();

  Hasher combine(Object value) {
    _hash = _combine(_hash, value.hashCode);
    return this;
  }

  int finalize() {
    var hash = 0x1fffffff & (_hash + ((0x03ffffff & _hash) << 3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }

  int _combine(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }
}