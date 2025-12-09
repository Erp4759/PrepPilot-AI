import 'package:flutter/foundation.dart';

/// Simple singleton notifier to broadcast that new results were created.
class ResultsNotifier extends ChangeNotifier {
  ResultsNotifier._privateConstructor();

  static final ResultsNotifier _instance =
      ResultsNotifier._privateConstructor();

  static ResultsNotifier get instance => _instance;

  /// Call this when a new result is saved (server-side) to prompt listeners to reload.
  void notifyNewResult(String resultId) {
    // We don't need to store the id here, listeners will typically call the API again.
    notifyListeners();
  }
}
