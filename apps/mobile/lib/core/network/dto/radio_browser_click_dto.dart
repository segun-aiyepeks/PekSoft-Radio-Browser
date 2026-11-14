/// Raw DTO for `/json/url/{stationuuid}` click-reporting response.
class RadioBrowserClickDto {
  const RadioBrowserClickDto({
    required this.ok,
    required this.message,
    required this.stationuuid,
    required this.name,
    required this.url,
  });

  factory RadioBrowserClickDto.fromJson(Map<String, dynamic> json) {
    final dynamic rawOk = json['ok'];
    final bool ok = rawOk is bool
        ? rawOk
        : (rawOk is String ? rawOk.toLowerCase() == 'true' : false);
    return RadioBrowserClickDto(
      ok: ok,
      message: (json['message'] as String?) ?? '',
      stationuuid: (json['stationuuid'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      url: (json['url'] as String?) ?? '',
    );
  }

  final bool ok;
  final String message;
  final String stationuuid;
  final String name;
  final String url;
}
