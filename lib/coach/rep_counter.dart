/// Counts reps from a 0–100 contraction signal with hysteresis.
class RepCounter {
  RepCounter({this.enterTop = 80.0, this.enterBottom = 20.0})
      : assert(enterTop > enterBottom);

  final double enterTop;
  final double enterBottom;

  int reps = 0;
  bool _atTop = false;

  /// Returns true on the frame a rep completes.
  bool update(double signal) {
    if (signal >= enterTop) {
      _atTop = true;
      return false;
    }
    if (signal <= enterBottom && _atTop) {
      _atTop = false;
      reps++;
      return true;
    }
    return false;
  }

  void reset() {
    reps = 0;
    _atTop = false;
  }
}
