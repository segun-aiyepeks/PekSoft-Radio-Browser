/// Raw DTO for `/json/servers` entries.
class RadioBrowserServerDto {
  const RadioBrowserServerDto({required this.ip, required this.name});

  factory RadioBrowserServerDto.fromJson(Map<String, dynamic> json) {
    return RadioBrowserServerDto(
      ip: (json['ip'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
    );
  }

  final String ip;
  final String name;
}
