import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Extension for easier access to localized strings
extension L10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
