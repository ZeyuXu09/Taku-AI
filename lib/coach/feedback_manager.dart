class Fault {
  const Fault(this.key, this.active, this.message);

  final String key;
  final bool active;
  final String message;
}

class FeedbackDecision {
  const FeedbackDecision(this.message, this.isNew);

  final String? message;
  final bool isNew;
}

/// Surfaces the highest-priority fault that has persisted for [hold].
class FeedbackManager {
  FeedbackManager({this.hold = const Duration(milliseconds: 1200)});

  final Duration hold;
  final Map<String, DateTime> _activeSince = {};
  String? _lastMessage;

  FeedbackDecision evaluate(List<Fault> faults, DateTime now) {
    final stillActive = <String>{};
    String? emit;

    for (final fault in faults) {
      if (!fault.active) continue;
      stillActive.add(fault.key);
      final since = _activeSince.putIfAbsent(fault.key, () => now);
      if (emit == null && now.difference(since) >= hold) {
        emit = fault.message;
      }
    }

    _activeSince.removeWhere((key, _) => !stillActive.contains(key));

    final isNew = emit != null && emit != _lastMessage;
    _lastMessage = emit;
    return FeedbackDecision(emit, isNew);
  }

  void reset() {
    _activeSince.clear();
    _lastMessage = null;
  }
}
