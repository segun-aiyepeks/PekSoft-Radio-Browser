import 'package:flutter/material.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/utils/country_flag.dart';

/// Displays a real crisp national flag image for an ISO-2 country code,
/// falling back to the Unicode flag emoji when offline or invalid.
class CountryFlagImage extends StatelessWidget {
  const CountryFlagImage({
    super.key,
    required this.countryCode,
    this.width = 28,
    this.height = 20,
    this.borderRadius = 4,
  });

  final String countryCode;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final code = countryCode.trim().toLowerCase();
    final isValid = RegExp(r'^[a-z]{2}$').hasMatch(code);

    Widget emojiFallback() => Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        countryFlagEmoji(countryCode),
        style: TextStyle(fontSize: height * 0.72),
      ),
    );

    if (!isValid) return emojiFallback();

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        'https://flagcdn.com/w80/$code.png',
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => emojiFallback(),
      ),
    );
  }
}
