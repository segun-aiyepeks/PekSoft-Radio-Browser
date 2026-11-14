/// Converts a 2-letter ISO 3166-1 alpha-2 country code (e.g. `NG`) into its
/// Unicode flag emoji (`🇳🇬`). Returns `🌍` if [countryCode] is invalid.
String countryFlagEmoji(String countryCode) {
  final String code = countryCode.trim().toUpperCase();
  if (code.length != 2) {
    return '🌍';
  }
  final int first = code.codeUnitAt(0);
  final int second = code.codeUnitAt(1);
  if (first < 0x41 || first > 0x5A || second < 0x41 || second > 0x5A) {
    return '🌍';
  }
  const int regionalOffset = 0x1F1E6 - 0x41;
  return String.fromCharCode(first + regionalOffset) +
      String.fromCharCode(second + regionalOffset);
}
