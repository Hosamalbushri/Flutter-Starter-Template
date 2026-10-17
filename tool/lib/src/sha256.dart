import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Pure-Dart SHA-256 implementation with zero external package dependencies.
/// Supports single-pass byte hashing, string hashing, and chunked streaming.
final class Sha256 {
  const Sha256._();

  static final List<int> _k = [
    0x428a2f98,
    0x71374491,
    0xb5c0fbcf,
    0xe9b5dba5,
    0x3956c25b,
    0x59f111f1,
    0x923f82a4,
    0xab1c5ed5,
    0xd807aa98,
    0x12835b01,
    0x243185be,
    0x550c7dc3,
    0x72be5d74,
    0x80deb1fe,
    0x9bdc06a7,
    0xc19bf174,
    0xe49b69c1,
    0xefbe4786,
    0x0fc19dc6,
    0x240ca1cc,
    0x2de92c6f,
    0x4a7484aa,
    0x5cb0a9dc,
    0x76f988da,
    0x983e5152,
    0xa831c66d,
    0xb00327c8,
    0xbf597fc7,
    0xc6e00bf3,
    0xd5a79147,
    0x06ca6351,
    0x14292967,
    0x27b70a85,
    0x2e1b2138,
    0x4d2c6dfc,
    0x53380d13,
    0x650a7354,
    0x766a0abb,
    0x81c2c92e,
    0x92722c85,
    0xa2bfe8a1,
    0xa81a664b,
    0xc24b8b70,
    0xc76c51a3,
    0xd192e819,
    0xd6990624,
    0xf40e3585,
    0x106aa070,
    0x19a4c116,
    0x1e376c08,
    0x2748774c,
    0x34b0bcb5,
    0x391c0cb3,
    0x4ed8aa4a,
    0x5b9cca4f,
    0x682e6ff3,
    0x748f82ee,
    0x78a5636f,
    0x84c87814,
    0x8cc70208,
    0x90befffa,
    0xa4506ceb,
    0xbef9a3f7,
    0xc67178f2,
  ];

  static String hashBytes(List<int> bytes) {
    final sink = Sha256Sink();
    sink.add(bytes);
    return sink.close();
  }

  static String hashString(String input) => hashBytes(utf8.encode(input));

  static Future<String> hashFile(File file) async {
    final sink = Sha256Sink();
    await file.openRead().forEach(sink.add);
    return sink.close();
  }

  static String hashFileSync(File file) {
    final sink = Sha256Sink();
    final randomAccess = file.openSync();
    try {
      final buffer = Uint8List(64 * 1024);
      int bytesRead;
      while ((bytesRead = randomAccess.readIntoSync(buffer)) > 0) {
        if (bytesRead == buffer.length) {
          sink.add(buffer);
        } else {
          sink.add(buffer.sublist(0, bytesRead));
        }
      }
    } finally {
      randomAccess.closeSync();
    }
    return sink.close();
  }
}

/// Incremental / streaming SHA-256 sink supporting arbitrary chunk sizes.
final class Sha256Sink {
  Sha256Sink();

  int _h0 = 0x6a09e667;
  int _h1 = 0xbb67ae85;
  int _h2 = 0x3c6ef372;
  int _h3 = 0xa54ff53a;
  int _h4 = 0x510e527f;
  int _h5 = 0x9b05688c;
  int _h6 = 0x1f83d9ab;
  int _h7 = 0x5be0cd19;

  final Uint8List _buffer = Uint8List(64);
  int _bufferLen = 0;
  int _totalBytes = 0;
  final List<int> _w = List<int>.filled(64, 0);

  void add(List<int> data) {
    _totalBytes += data.length;
    var offset = 0;
    while (offset < data.length) {
      final toCopy = 64 - _bufferLen;
      final available = data.length - offset;
      if (available < toCopy) {
        _buffer.setRange(_bufferLen, _bufferLen + available, data, offset);
        _bufferLen += available;
        break;
      } else {
        _buffer.setRange(_bufferLen, 64, data, offset);
        offset += toCopy;
        _bufferLen = 0;
        _processBlock(_buffer, 0);
      }
    }
  }

  void _processBlock(Uint8List block, int offset) {
    final byteData = ByteData.sublistView(block, offset, offset + 64);
    for (var i = 0; i < 16; i++) {
      _w[i] = byteData.getUint32(i * 4, Endian.big);
    }
    for (var i = 16; i < 64; i++) {
      final s0 =
          _rotr(_w[i - 15], 7) ^ _rotr(_w[i - 15], 18) ^ (_w[i - 15] >>> 3);
      final s1 =
          _rotr(_w[i - 2], 17) ^ _rotr(_w[i - 2], 19) ^ (_w[i - 2] >>> 10);
      _w[i] = (_w[i - 16] + s0 + _w[i - 7] + s1) & 0xffffffff;
    }

    var a = _h0;
    var b = _h1;
    var c = _h2;
    var d = _h3;
    var e = _h4;
    var f = _h5;
    var g = _h6;
    var h = _h7;

    for (var i = 0; i < 64; i++) {
      final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final ch = (e & f) ^ ((~e) & g);
      final temp1 = (h + s1 + ch + Sha256._k[i] + _w[i]) & 0xffffffff;
      final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final temp2 = (s0 + maj) & 0xffffffff;

      h = g;
      g = f;
      f = e;
      e = (d + temp1) & 0xffffffff;
      d = c;
      c = b;
      b = a;
      a = (temp1 + temp2) & 0xffffffff;
    }

    _h0 = (_h0 + a) & 0xffffffff;
    _h1 = (_h1 + b) & 0xffffffff;
    _h2 = (_h2 + c) & 0xffffffff;
    _h3 = (_h3 + d) & 0xffffffff;
    _h4 = (_h4 + e) & 0xffffffff;
    _h5 = (_h5 + f) & 0xffffffff;
    _h6 = (_h6 + g) & 0xffffffff;
    _h7 = (_h7 + h) & 0xffffffff;
  }

  String close() {
    final bitLength = _totalBytes * 8;
    if (_bufferLen < 56) {
      _buffer.setRange(_bufferLen, _bufferLen + 1, [0x80]);
      _buffer.fillRange(_bufferLen + 1, 56, 0);
      ByteData.sublistView(_buffer, 56, 64).setUint64(0, bitLength, Endian.big);
      _processBlock(_buffer, 0);
    } else {
      _buffer.setRange(_bufferLen, _bufferLen + 1, [0x80]);
      _buffer.fillRange(_bufferLen + 1, 64, 0);
      _processBlock(_buffer, 0);

      final second = Uint8List(64);
      second.fillRange(0, 56, 0);
      ByteData.sublistView(second, 56, 64).setUint64(0, bitLength, Endian.big);
      _processBlock(second, 0);
    }

    String hex(int val) => val.toRadixString(16).padLeft(8, '0');
    return '${hex(_h0)}${hex(_h1)}${hex(_h2)}${hex(_h3)}${hex(_h4)}${hex(_h5)}${hex(_h6)}${hex(_h7)}';
  }

  static int _rotr(int x, int n) => ((x >>> n) | (x << (32 - n))) & 0xffffffff;
}
