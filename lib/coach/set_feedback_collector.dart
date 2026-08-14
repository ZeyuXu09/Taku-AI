import 'package:peakform_ai/coach/feedback_manager.dart';

class _FaultStat {
  _FaultStat(this.coaching);

  String coaching;
  int hits = 1;
}

class SetFeedbackNote {
  const SetFeedbackNote({
    required this.message,
    required this.isCorrection,
    required this.reps,
  });

  final String message;
  final bool isCorrection;
  final int reps;
}

/// Builds one longer coaching note per set instead of a cue every few seconds.
class SetFeedbackCollector {
  bool _started = false;
  bool _closed = false;
  int _goodFrames = 0;
  int _badFrames = 0;
  Duration _peakHold = Duration.zero;
  final Map<String, _FaultStat> _stats = {};

  bool get inProgress => _started && !_closed;

  bool get _hasEnoughWork =>
      _setReps >= 1 || _peakHold >= const Duration(seconds: 2);

  int _baseReps = 0;
  int _setReps = 0;

  void observeFrame({
    required bool formGood,
    required List<Fault> faults,
    required int reps,
    required Duration hold,
  }) {
    if (_closed) {
      reset();
    }

    if (!_started) {
      _baseReps = reps;
      _started = true;
    }

    _setReps = reps < _baseReps ? 0 : reps - _baseReps;
    if (hold > _peakHold) _peakHold = hold;
    if (formGood) {
      _goodFrames++;
    } else {
      _badFrames++;
    }

    for (final fault in faults) {
      if (!fault.active) continue;
      final existing = _stats[fault.key];
      if (existing == null) {
        _stats[fault.key] = _FaultStat(fault.coaching);
      } else {
        existing.hits++;
        existing.coaching = fault.coaching;
      }
    }
  }

  /// Returns one detailed note and closes the set. Null if nothing to say yet.
  SetFeedbackNote? finish({
    required String exerciseTitle,
    required bool isStatic,
    bool force = false,
  }) {
    if (!_started || _closed) return null;
    if (!_hasEnoughWork) {
      if (force) reset();
      return null;
    }

    final total = _goodFrames + _badFrames;
    final goodRatio = total == 0 ? 1.0 : _goodFrames / total;
    final isCorrection = _stats.isNotEmpty && goodRatio < 0.75;
    _closed = true;
    return SetFeedbackNote(
      message: _compose(exerciseTitle: exerciseTitle, isStatic: isStatic),
      isCorrection: isCorrection,
      reps: _setReps,
    );
  }

  void reset() {
    _started = false;
    _closed = false;
    _goodFrames = 0;
    _badFrames = 0;
    _baseReps = 0;
    _setReps = 0;
    _peakHold = Duration.zero;
    _stats.clear();
  }

  String _compose({
    required String exerciseTitle,
    required bool isStatic,
  }) {
    final ranked = _stats.entries.toList()
      ..sort((a, b) => b.value.hits.compareTo(a.value.hits));
    final total = _goodFrames + _badFrames;
    final goodRatio = total == 0 ? 1.0 : _goodFrames / total;
    final name = exerciseTitle.toLowerCase();

    final buffer = StringBuffer();
    if (isStatic) {
      buffer.write('${_capitalize(exerciseTitle)} hold: ${_formatHold(_peakHold)}. ');
    } else if (_setReps <= 0) {
      buffer.write('$exerciseTitle set. ');
    } else if (_setReps == 1) {
      buffer.write('Set of 1 ${_singular(name)}. ');
    } else {
      buffer.write('Set of $_setReps $name. ');
    }

    if (ranked.isEmpty || goodRatio >= 0.75) {
      buffer.write('Overall form looked strong');
      if (ranked.isEmpty) {
        buffer.write(
          '. Keep the same control and tension next set — that quality is what you want to repeat.',
        );
      } else {
        buffer.write(', with one thing to tighten up. ');
        buffer.write(ranked.first.value.coaching);
      }
    } else {
      buffer.write(ranked.first.value.coaching);
      if (ranked.length > 1 &&
          ranked[1].value.hits >= (ranked.first.value.hits * 0.4).round()) {
        buffer.write(' ');
        buffer.write(ranked[1].value.coaching);
      }
    }

    return buffer.toString().trim();
  }

  String _formatHold(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  String _singular(String name) {
    if (name.endsWith('s') && !name.endsWith('ss')) {
      return name.substring(0, name.length - 1);
    }
    return name;
  }
}
