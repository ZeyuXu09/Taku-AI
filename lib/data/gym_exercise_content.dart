import 'package:peakform_ai/models/exercise_guide.dart';

/// Gym-specific how-to guides (ids prefixed with `gym_`).
const gymExerciseGuides = <String, ExerciseGuide>{
  'gym_bench_press': ExerciseGuide(
    steps: [
      'Lie on the bench with eyes under the bar, feet flat on the floor.',
      'Grip slightly wider than shoulders, unrack, and lower the bar to mid-chest.',
      'Press up until arms are extended without locking elbows harshly.',
      'Re-rack with straight wrists and control.',
    ],
    notes:
        'Use a spotter when lifting heavy. Keep shoulder blades pinched back and down throughout.',
  ),
  'gym_back_squat': ExerciseGuide(
    steps: [
      'Set the bar on upper traps, stand with feet shoulder-width apart.',
      'Brace core, sit hips back and down keeping chest up.',
      'Descend until thighs are at least parallel, then drive up through mid-foot.',
      'Finish standing tall without hyperextending the lower back.',
    ],
    notes:
        'Use safety bars or a spotter. Keep knees tracking over toes — don\'t let them cave inward.',
  ),
  'gym_barbell_row': ExerciseGuide(
    steps: [
      'Hinge forward with a flat back, bar hanging at arm\'s length.',
      'Pull the bar to your lower ribs, driving elbows back.',
      'Squeeze shoulder blades at the top, then lower under control.',
    ],
    notes: 'Avoid using momentum from the hips. Torso angle stays fixed during the set.',
  ),
  'gym_lat_pulldown': ExerciseGuide(
    steps: [
      'Sit with thighs secured under the pad, grip bar wider than shoulders.',
      'Pull the bar to upper chest while leaning slightly back.',
      'Control the return until arms are nearly straight.',
    ],
    notes: 'Don\'t pull behind the neck. Think elbows to back pockets, not hands to chest.',
  ),
  'gym_leg_press': ExerciseGuide(
    steps: [
      'Sit with back flat against the pad, feet shoulder-width on the platform.',
      'Lower until knees bend to roughly 90° without hips rolling off the seat.',
      'Press through mid-foot to extend legs without locking knees.',
    ],
    notes: 'Don\'t let lower back round at the bottom. Adjust foot height to target quads vs glutes.',
  ),
  'gym_trap_bar_deadlift': ExerciseGuide(
    steps: [
      'Stand inside the trap bar, grab handles, hips back, chest up.',
      'Drive through the floor, extending hips and knees together.',
      'Stand tall at the top, then hinge back down with control.',
    ],
    notes: 'Often easier on the lower back than conventional deadlifts. Keep the bar path vertical.',
  ),
  'gym_power_clean': ExerciseGuide(
    steps: [
      'Start with bar over mid-foot, grip shoulder-width, hips higher than knees.',
      'First pull: bar stays close as you extend hips and knees.',
      'Explode upward, shrug and drop under the bar into a front-rack catch.',
    ],
    notes: 'Use light weight until technique is solid. Best learned with a coach if new to Olympic lifts.',
  ),
  'gym_treadmill_sprints': ExerciseGuide(
    steps: [
      'Warm up 3–5 min at easy pace.',
      'Set incline (3–8%) and sprint at high effort for the interval.',
      'Step to side rails or slow walk during rest — don\'t jump off a moving belt.',
    ],
    notes: 'Hold the rails only for balance if needed, not to support body weight during sprints.',
  ),
  'gym_assault_bike': ExerciseGuide(
    steps: [
      'Adjust seat so knee has slight bend at bottom of pedal stroke.',
      'Drive hard with arms and legs together for each work interval.',
      'Ease off during rest, keep pedaling lightly to recover.',
    ],
    notes: 'Full-body conditioning — pace yourself early so later intervals stay strong.',
  ),
  'gym_cable_face_pull': ExerciseGuide(
    steps: [
      'Set cable at upper-chest height with rope attachment.',
      'Pull rope toward face, elbows high and wide.',
      'Externally rotate at end range, then return with control.',
    ],
    notes: 'Great for shoulder health. Use light-moderate weight and feel rear delts working.',
  ),
};
