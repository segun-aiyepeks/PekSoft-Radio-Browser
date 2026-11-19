import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:share_plus/share_plus.dart';

/// Builds the canonical share URL for a station.
String buildStationShareUrl(Station station) =>
    'https://peksoft.radio/station/${station.id}';

/// Builds the share message text for social & messaging apps
/// (WhatsApp, Telegram, Facebook, Messages, etc.).
String buildStationShareText(Station station) {
  final String location =
      station.countryName.isNotEmpty ? ' (${station.countryName})' : '';
  return 'Listen to ${station.name}$location live on PekSoft Radio Browser!\n${buildStationShareUrl(station)}';
}

/// Opens the native Android/iOS share sheet so the user can share [station]
/// directly to WhatsApp, Telegram, Facebook, Messages, or copy the link.
///
/// Falls back to copying the share link to the clipboard if the native share
/// sheet is unavailable on the current platform.
Future<void> shareStation(BuildContext context, Station station) async {
  final String shareText = buildStationShareText(station);
  final String shareUrl = buildStationShareUrl(station);

  Rect? sharePositionOrigin;
  final RenderObject? renderObject = context.findRenderObject();
  if (renderObject is RenderBox && renderObject.hasSize) {
    sharePositionOrigin =
        renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  try {
    await SharePlus.instance.share(
      ShareParams(
        text: shareText,
        subject: '${station.name} · PekSoft Radio Browser',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: shareUrl));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share link copied: $shareUrl')),
      );
    }
  }
}
