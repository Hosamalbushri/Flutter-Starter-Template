/// Returns a user-facing validation message when [rawUrl] is not a supported
/// web URL, or `null` when it is valid.
String? validateBookmarkUrl(String rawUrl) {
  final value = rawUrl.trim();
  if (value.isEmpty) return 'URL is required.';

  final uri = Uri.tryParse(value);
  final scheme = uri?.scheme.toLowerCase();
  if (uri == null ||
      (scheme != 'http' && scheme != 'https') ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return 'URL must be a valid HTTP or HTTPS URL.';
  }

  return null;
}

/// Produces a duplicate-comparison key without changing case-sensitive URL
/// components such as paths, queries, and fragments.
String canonicalizeBookmarkUrl(String rawUrl) {
  final value = rawUrl.trim();
  final uri = Uri.tryParse(value);
  if (uri == null || uri.host.isEmpty) return value;

  return uri
      .replace(
        scheme: uri.scheme.toLowerCase(),
        host: uri.host.toLowerCase(),
      )
      .toString();
}
