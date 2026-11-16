import 'package:peksoft_radio/features/station/domain/station.dart';

/// Selects a lower-bitrate stream variant when [dataSaver] is enabled and
/// matching working variants exist in [candidates].
Station selectBitrateVariant(
  Station requested,
  List<Station> candidates, {
  required bool dataSaver,
}) {
  if (!dataSaver || candidates.isEmpty) {
    return requested;
  }

  final String targetName = requested.name.trim().toLowerCase();
  final String targetCountry = requested.countryCode.trim().toUpperCase();

  final List<Station> matching = candidates
      .where(
        (Station c) =>
            c.isWorking &&
            c.bitrateKbps > 0 &&
            c.name.trim().toLowerCase() == targetName &&
            c.countryCode.trim().toUpperCase() == targetCountry,
      )
      .toList(growable: false);

  if (matching.isEmpty) {
    return requested;
  }

  Station best = requested;
  for (final Station candidate in matching) {
    if (best.bitrateKbps <= 0 || candidate.bitrateKbps < best.bitrateKbps) {
      best = candidate;
    }
  }

  if (best.id == requested.id && best.streamUrl == requested.streamUrl) {
    return requested;
  }

  return best.copyWith(
    fallbackStreamUrl: best.fallbackStreamUrl ?? requested.streamUrl,
  );
}
