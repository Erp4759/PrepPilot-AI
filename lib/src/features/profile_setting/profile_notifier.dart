import 'package:flutter/foundation.dart';

/// Simple notifier to signal that the user's profile changed and
/// interested screens should reload. Increment the counter to notify.
final ValueNotifier<int> profileRefreshCounter = ValueNotifier<int>(0);
