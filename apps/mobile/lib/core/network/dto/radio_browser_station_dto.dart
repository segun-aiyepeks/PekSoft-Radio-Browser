/// Raw DTO matching the 37 real fields observed in Phase 0
/// `stations-sample-200.json`.
class RadioBrowserStationDto {
  const RadioBrowserStationDto({
    required this.stationuuid,
    required this.changeuuid,
    this.serveruuid,
    required this.name,
    required this.url,
    required this.urlResolved,
    required this.homepage,
    required this.favicon,
    required this.tags,
    required this.country,
    required this.countrycode,
    this.iso31662,
    required this.state,
    required this.language,
    required this.languagecodes,
    required this.votes,
    required this.clickcount,
    required this.clicktrend,
    required this.codec,
    required this.bitrate,
    required this.hls,
    required this.lastcheckok,
    required this.sslError,
    this.geoLat,
    this.geoLong,
    this.geoDistance,
    required this.hasExtendedInfo,
    required this.lastchangetime,
    this.lastchangetimeIso8601,
    required this.lastchecktime,
    this.lastchecktimeIso8601,
    required this.lastcheckoktime,
    this.lastcheckoktimeIso8601,
    required this.lastlocalchecktime,
    this.lastlocalchecktimeIso8601,
    required this.clicktimestamp,
    this.clicktimestampIso8601,
  });

  factory RadioBrowserStationDto.fromJson(Map<String, dynamic> json) {
    return RadioBrowserStationDto(
      stationuuid: (json['stationuuid'] as String?) ?? '',
      changeuuid: (json['changeuuid'] as String?) ?? '',
      serveruuid: json['serveruuid'] as String?,
      name: (json['name'] as String?) ?? '',
      url: (json['url'] as String?) ?? '',
      urlResolved: (json['url_resolved'] as String?) ?? '',
      homepage: (json['homepage'] as String?) ?? '',
      favicon: (json['favicon'] as String?) ?? '',
      tags: (json['tags'] as String?) ?? '',
      country: (json['country'] as String?) ?? '',
      countrycode: (json['countrycode'] as String?) ?? '',
      iso31662: json['iso_3166_2'] as String?,
      state: (json['state'] as String?) ?? '',
      language: (json['language'] as String?) ?? '',
      languagecodes: (json['languagecodes'] as String?) ?? '',
      votes: (json['votes'] as num?)?.toInt() ?? 0,
      clickcount: (json['clickcount'] as num?)?.toInt() ?? 0,
      clicktrend: (json['clicktrend'] as num?)?.toInt() ?? 0,
      codec: (json['codec'] as String?) ?? '',
      bitrate: (json['bitrate'] as num?)?.toInt() ?? 0,
      hls: (json['hls'] as num?)?.toInt() ?? 0,
      lastcheckok: (json['lastcheckok'] as num?)?.toInt() ?? 0,
      sslError: (json['ssl_error'] as num?)?.toInt() ?? 0,
      geoLat: (json['geo_lat'] as num?)?.toDouble(),
      geoLong: (json['geo_long'] as num?)?.toDouble(),
      geoDistance: (json['geo_distance'] as num?)?.toDouble(),
      hasExtendedInfo: (json['has_extended_info'] as bool?) ?? false,
      lastchangetime: (json['lastchangetime'] as String?) ?? '',
      lastchangetimeIso8601: json['lastchangetime_iso8601'] as String?,
      lastchecktime: (json['lastchecktime'] as String?) ?? '',
      lastchecktimeIso8601: json['lastchecktime_iso8601'] as String?,
      lastcheckoktime: (json['lastcheckoktime'] as String?) ?? '',
      lastcheckoktimeIso8601: json['lastcheckoktime_iso8601'] as String?,
      lastlocalchecktime: (json['lastlocalchecktime'] as String?) ?? '',
      lastlocalchecktimeIso8601: json['lastlocalchecktime_iso8601'] as String?,
      clicktimestamp: (json['clicktimestamp'] as String?) ?? '',
      clicktimestampIso8601: json['clicktimestamp_iso8601'] as String?,
    );
  }

  final String stationuuid;
  final String changeuuid;
  final String? serveruuid;
  final String name;
  final String url;
  final String urlResolved;
  final String homepage;
  final String favicon;
  final String tags;
  final String country;
  final String countrycode;
  final String? iso31662;
  final String state;
  final String language;
  final String languagecodes;
  final int votes;
  final int clickcount;
  final int clicktrend;
  final String codec;
  final int bitrate;
  final int hls;
  final int lastcheckok;
  final int sslError;
  final double? geoLat;
  final double? geoLong;
  final double? geoDistance;
  final bool hasExtendedInfo;
  final String lastchangetime;
  final String? lastchangetimeIso8601;
  final String lastchecktime;
  final String? lastchecktimeIso8601;
  final String lastcheckoktime;
  final String? lastcheckoktimeIso8601;
  final String lastlocalchecktime;
  final String? lastlocalchecktimeIso8601;
  final String clicktimestamp;
  final String? clicktimestampIso8601;
}
