import 'package:flutter/foundation.dart';

// Global notifier for app-wide font size so any screen can update it
final ValueNotifier<int> appFontSizeNotifier = ValueNotifier<int>(16);
// Global notifier for app-wide theme selection (0 = light, 1 = dark)
final ValueNotifier<int> appThemeNotifier = ValueNotifier<int>(0);