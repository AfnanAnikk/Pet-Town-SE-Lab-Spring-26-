import 'package:flutter/foundation.dart';

/// Singleton ChangeNotifier used to broadcast that event data has changed.
///
/// Any page in the Event module should:
///   1. Call [EventChangeNotifier.instance.addListener(_load)] in [initState].
///   2. Call [EventChangeNotifier.instance.removeListener(_load)] in [dispose].
///
/// Any action that mutates event state (save, unsave, join, leave, create,
/// edit, delete, accept/decline invitation) should call:
///   [EventChangeNotifier.instance.notify()]
///
/// This causes every subscribed page to reload its data automatically.
class EventChangeNotifier extends ChangeNotifier {
  EventChangeNotifier._();
  static final EventChangeNotifier instance = EventChangeNotifier._();

  /// Call this after any state-mutating event action.
  void notify() => notifyListeners();
}
