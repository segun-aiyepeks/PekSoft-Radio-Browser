/// Raw DTO for `/json/countries` entries.
class RadioBrowserCountryDto {
  const RadioBrowserCountryDto({
    required this.name,
    required this.iso31661,
    required this.stationcount,
  });

  factory RadioBrowserCountryDto.fromJson(Map<String, dynamic> json) {
    return RadioBrowserCountryDto(
      name: (json['name'] as String?) ?? '',
      iso31661: (json['iso_3166_1'] as String?) ?? '',
      stationcount: (json['stationcount'] as num?)?.toInt() ?? 0,
    );
  }

  final String name;
  final String iso31661;
  final int stationcount;
}
