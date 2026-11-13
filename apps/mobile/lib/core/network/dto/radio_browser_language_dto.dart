/// Raw DTO for `/json/languages` entries.
class RadioBrowserLanguageDto {
  const RadioBrowserLanguageDto({
    required this.name,
    this.iso639,
    required this.stationcount,
  });

  factory RadioBrowserLanguageDto.fromJson(Map<String, dynamic> json) {
    return RadioBrowserLanguageDto(
      name: (json['name'] as String?) ?? '',
      iso639: json['iso_639'] as String?,
      stationcount: (json['stationcount'] as num?)?.toInt() ?? 0,
    );
  }

  final String name;
  final String? iso639;
  final int stationcount;
}
