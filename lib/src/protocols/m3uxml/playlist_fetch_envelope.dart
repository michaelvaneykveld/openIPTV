import 'dart:convert';
import 'dart:typed_data';

/// Represents the raw bytes fetched from a playlist or XMLTV source along
/// with HTTP metadata that helps implement caching and retries.
class PlaylistFetchEnvelope {
  /// Binary payload as delivered by the source (possibly compressed). Using
  /// `Uint8List` keeps the object immutable and efficient for large files.
  final Uint8List bytes;

  /// Optional MIME type reported by the server. Local sources leave this null.
  final String? contentType;

  /// Optional content encoding (e.g. `gzip`, `xz`). Helps the caller decide
  /// whether bytes need decompression before parsing.
  final String? contentEncoding;

  /// Optional ETag header value returned by HTTP servers. The sync layer can
  /// persist it to implement conditional GET requests.
  final String? etag;

  /// Optional Last-Modified header value for similar caching purposes.
  final DateTime? lastModified;

  /// HTTP status code when the payload came from a remote source. Local file
  /// reads set this to 200 by convention.
  final int statusCode;

  PlaylistFetchEnvelope({
    required Uint8List bytes,
    this.contentType,
    this.contentEncoding,
    this.etag,
    this.lastModified,
    this.statusCode = 200,
  }) : bytes = Uint8List.fromList(bytes);

  /// Returns true when the body appears to be gzip compressed. We inspect
  /// both the declared `contentEncoding` and the magic header bytes so we
  /// can gracefully handle misconfigured servers.
  bool get isGzipEncoded {
    if (contentEncoding != null &&
        contentEncoding!.toLowerCase().contains('gzip')) {
      return true;
    }
    // Check magic number 0x1F8B.
    return bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b;
  }

  /// Returns true when the server reported XZ compression. We do not decode
  /// XZ yet, but detecting it allows us to emit informative errors.
  bool get isXzEncoded {
    if (contentEncoding != null &&
        contentEncoding!.toLowerCase().contains('xz')) {
      return true;
    }
    // Magic number for XZ: FD 37 7A 58 5A 00.
    const signature = [0xFD, 0x37, 0x7A, 0x58, 0x5A, 0x00];
    if (bytes.length < signature.length) {
      return false;
    }
    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) {
        return false;
      }
    }
    return true;
  }

  /// Decodes the payload into a string, transparently handling gzip when
  /// necessary. XMLTV feeds are often huge; the caller can choose to parse
  /// in a streaming fashion if desired by working with the bytes directly.
  String decodeBody({Encoding encoding = utf8}) {
    if (isXzEncoded) {
      throw const FormatException(
        'XZ-compressed feeds are not supported yet. Decompress before parsing.',
      );
    }
    var data = bytes;
    if (isGzipEncoded) {
      data = Uint8List.fromList(const GZipCodec().decode(bytes));
    }
    return encoding.decode(data);
  }
}

