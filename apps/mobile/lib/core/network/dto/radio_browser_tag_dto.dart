/// Raw DTO for `/json/tags` entries.
class RadioBrowserTagDto {
  const RadioBrowserTagDto({required this.name, required this.stationcount});

  factory RadioBrowserTagDto.fromJson(Map<String, dynamic> json) {
    return RadioBrowserTagDto(
      name: (json['name'] as String?) ?? '',
      stationcount: (json['stationcount'] as num?)?.toInt() ?? 0,
    );
  }

  final String name;
  final int stationcount;
}
