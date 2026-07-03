import 'package:peakform_ai/data/gym_exercise_content.dart';
import 'package:peakform_ai/models/exercise_guide.dart';
import 'package:peakform_ai/models/training_exercise.dart';

const exerciseGuides = <String, ExerciseGuide>{
  'box_jumps': ExerciseGuide(
    steps: [
      'Stand arm\'s length from a sturdy box or platform at a comfortable height.',
      'Swing arms back, bend knees, then explode upward onto the box.',
      'Land softly with both feet fully on top, knees slightly bent.',
      'Stand tall, step down one foot at a time, and reset before the next rep.',
    ],
    notes:
        'Start low and progress height gradually. Step down — don\'t jump off — to protect knees and Achilles.',
  ),
  'broad_jumps': ExerciseGuide(
    steps: [
      'Stand with feet hip-width apart and arms ready to swing.',
      'Hinge at hips, bend knees, and swing arms back to load.',
      'Drive through the floor and jump forward as far as you can.',
      'Land softly in an athletic stance with knees bent and chest up.',
    ],
    notes:
        'Measure distance only after you can stick every landing. Avoid collapsing inward at the knees on impact.',
  ),
  'med_ball_slams': ExerciseGuide(
    steps: [
      'Hold a medicine ball overhead with arms extended and core braced.',
      'Rise onto toes slightly, then slam the ball straight down into the floor.',
      'Follow through with hips and core; catch or pick up the ball on the rebound.',
      'Reset posture before the next rep.',
    ],
    notes:
        'Use a non-bounce or dead ball if available. Keep the slam vertical — not toward your feet.',
  ),
  'kettlebell_swings': ExerciseGuide(
    steps: [
      'Stand with feet shoulder-width apart, kettlebell slightly in front.',
      'Hinge at hips, grab the handle, and hike the bell back between your legs.',
      'Drive hips forward to float the bell to chest height — arms stay relaxed.',
      'Let the bell swing back as you hinge again; repeat in a smooth rhythm.',
    ],
    notes:
        'Power comes from the hips, not the arms. Stop if your lower back rounds at the bottom.',
  ),
  'jump_squats': ExerciseGuide(
    steps: [
      'Stand with feet shoulder-width apart, chest up, core tight.',
      'Lower into a squat until thighs are roughly parallel.',
      'Explode upward into a jump, extending fully at the top.',
      'Land softly back into a squat and flow into the next rep.',
    ],
    notes:
        'Keep knees tracking over toes. Use fewer reps if landings get noisy or unstable.',
  ),
  'push_press': ExerciseGuide(
    steps: [
      'Start with a barbell or dumbbells at shoulder height, elbows slightly in front.',
      'Dip by bending knees a few inches while keeping torso upright.',
      'Drive through legs and press the weight overhead in one motion.',
      'Lock out with biceps near ears, then lower under control to shoulders.',
    ],
    notes:
        'The leg drive does most of the work. Avoid excessive layback in the lower back at lockout.',
  ),
  'lateral_shuttles': ExerciseGuide(
    steps: [
      'Mark two lines about 5–10 yards apart.',
      'Start in an athletic stance at one line facing sideways.',
      'Push off the outside foot and shuffle quickly to the opposite line.',
      'Touch the line, change direction, and repeat for the prescribed time.',
    ],
    notes:
        'Stay low with chest up. Don\'t cross feet — keep a wide, stable base for court and field sports.',
  ),
  'agility_ladder': ExerciseGuide(
    steps: [
      'Place an agility ladder flat on the ground.',
      'Choose a pattern (e.g. one foot per square, in-in-out-out).',
      'Move through the ladder quickly while staying on the balls of your feet.',
      'Pump arms naturally and keep eyes up when possible.',
    ],
    notes:
        'Prioritize crisp foot contacts over max speed at first. Progress patterns before adding speed.',
  ),
  'cone_weaves': ExerciseGuide(
    steps: [
      'Set 4–6 cones in a straight line about 3–5 yards apart.',
      'Sprint toward the first cone and cut around it on the outside.',
      'Weave through each cone, staying low through every change of direction.',
      'Accelerate out of the last cone to finish the rep.',
    ],
    notes:
        'Plant the outside foot hard on cuts. Decrease cone spacing if you\'re upright through turns.',
  ),
  't_drill': ExerciseGuide(
    steps: [
      'Set cones in a T shape: one vertical line and one crossbar at the top.',
      'Sprint forward to the crossbar, shuffle left to the end, shuffle right across, then shuffle back to center.',
      'Backpedal to the start line to complete one rep.',
    ],
    notes:
        'Touch each cone with your hand to ensure full range. Keep hips low during shuffles.',
  ),
  'skater_hops': ExerciseGuide(
    steps: [
      'Stand on one leg in a slight athletic stance.',
      'Push off laterally and land on the opposite leg, letting the trailing leg swing behind for balance.',
      'Absorb the landing softly and immediately bound back the other direction.',
      'Continue side to side for the prescribed reps.',
    ],
    notes:
        'Great for tennis and racket sports. Start with small hops before going for max distance.',
  ),
  'reaction_starts': ExerciseGuide(
    steps: [
      'Start in an athletic ready position facing a partner, timer, or visual cue.',
      'On the signal, explode into a short sprint (5–15 yards).',
      'Decelerate under control at the end zone.',
      'Walk back, reset posture, and repeat.',
    ],
    notes:
        'Randomize start cues when possible to mimic match play. First step should be short and powerful.',
  ),
  'goblet_squats': ExerciseGuide(
    steps: [
      'Hold a dumbbell or kettlebell at chest height, elbows pointing down.',
      'Set feet shoulder-width apart with toes slightly out.',
      'Sit hips down and back, keeping chest up and elbows inside knees.',
      'Drive through mid-foot to stand, squeezing glutes at the top.',
    ],
    notes:
        'Use the weight as a counterbalance to keep torso upright. Depth is limited by maintaining a flat back.',
  ),
  'single_leg_squats': ExerciseGuide(
    steps: [
      'Stand on one leg; extend the other leg slightly in front or to the side for balance.',
      'Sit hips back and down on the standing leg, keeping knee aligned with toes.',
      'Lower as far as you can with control, then drive back up.',
      'Use a wall or TRX lightly for balance if needed.',
    ],
    notes:
        'Also called pistol squat progressions — use a box or bench behind you to limit depth while building strength.',
  ),
  'romanian_deadlift': ExerciseGuide(
    steps: [
      'Stand holding a barbell or dumbbells at hip height, feet hip-width apart.',
      'Push hips back while keeping a slight bend in the knees and a flat back.',
      'Lower until you feel a stretch in the hamstrings — usually mid-shin.',
      'Drive hips forward to return to standing, squeezing glutes.',
    ],
    notes:
        'This is a hip hinge, not a squat. Keep the weight close to your legs throughout.',
  ),
  'push_ups': ExerciseGuide(
    steps: [
      'Start in a high plank, hands slightly wider than shoulders, body in a straight line.',
      'Lower chest toward the floor, elbows at roughly 45° from the torso.',
      'Press back up without letting hips sag or pike up.',
      'Maintain a braced core for every rep.',
    ],
    notes:
        'Scale to knees or an incline if needed. Full range beats partial reps with poor form.',
  ),
  'pull_ups': ExerciseGuide(
    steps: [
      'Hang from a bar with hands shoulder-width apart, palms away or toward you.',
      'Pull chest toward the bar by driving elbows down and back.',
      'Pause briefly at the top with chin over or near the bar.',
      'Lower under control to a full hang.',
    ],
    notes:
        'Use assisted bands or inverted rows if full pull-ups aren\'t available yet. Avoid kipping unless prescribed.',
  ),
  'lunges': ExerciseGuide(
    steps: [
      'Stand tall with feet hip-width apart.',
      'Step forward and lower until both knees bend to about 90°.',
      'Keep front knee stacked over ankle and torso upright.',
      'Push through the front foot to step forward into the next lunge or return to stand.',
    ],
    notes:
        'Take a long enough step so the back knee doesn\'t crash into the floor. Alternate legs each rep unless noted.',
  ),
  'pallof_press': ExerciseGuide(
    steps: [
      'Set a cable or band at chest height and stand sideways to the anchor.',
      'Hold the handle at your sternum with both hands, feet shoulder-width apart.',
      'Press arms straight out in front, resisting rotation toward the cable.',
      'Hold briefly, return to chest, and repeat all reps before switching sides.',
    ],
    notes:
        'Anti-rotation core work — ideal for rotational sports. Keep hips and shoulders square throughout.',
  ),
  'sprint_intervals': ExerciseGuide(
    steps: [
      'Warm up with 5–10 minutes of easy movement and dynamic drills.',
      'Sprint at high effort for the prescribed interval (e.g. 20–40 sec).',
      'Walk or jog slowly during the rest period to recover.',
      'Repeat for all intervals and cool down afterward.',
    ],
    notes:
        'Each sprint should feel fast but controlled. Stop the session if hamstrings feel tight or form deteriorates.',
  ),
  'hill_sprints': ExerciseGuide(
    steps: [
      'Find a moderate hill (roughly 5–8% grade) with a safe surface.',
      'Sprint uphill with short, powerful strides and forward lean.',
      'Walk down slowly for recovery between reps.',
      'Reset fully before the next sprint.',
    ],
    notes:
        'Hills reduce impact while building power. Shorter hills (10–20 yards) work well for team-sport athletes.',
  ),
  'tempo_runs': ExerciseGuide(
    steps: [
      'Run at a steady, comfortably hard pace — you should speak in short phrases, not full sentences.',
      'Maintain even effort for the prescribed duration.',
      'Focus on relaxed shoulders and a quick cadence.',
      'Jog easily during rest intervals between sets.',
    ],
    notes:
        'Tempo pace is typically between easy jog and all-out sprint. Consistency matters more than speed spikes.',
  ),
  'suicides': ExerciseGuide(
    steps: [
      'Mark lines on a court or field (baseline, free-throw line, half court, opposite free throw, far baseline).',
      'Sprint to the first line, touch it, and return to start.',
      'Sprint to the next line and return, progressing farther each time.',
      'Complete one full suicide when you reach the far line and return.',
    ],
    notes:
        'Classic court conditioning. Touch lines with your hand and decelerate before sharp turns to protect ankles.',
  ),
  'battle_ropes': ExerciseGuide(
    steps: [
      'Anchor battle ropes and stand in an athletic stance, knees slightly bent.',
      'Hold one end in each hand with a firm grip.',
      'Create waves by alternating or simultaneous arm slams for the work interval.',
      'Keep core braced and breathe steadily throughout.',
    ],
    notes:
        'Stay rooted — movement comes from arms and core, not bouncing around. Reduce wave size if shoulders fatigue.',
  ),
  'burpees': ExerciseGuide(
    steps: [
      'From standing, drop hands to the floor and jump or step feet back to a plank.',
      'Optional push-up at the bottom, then jump or step feet toward hands.',
      'Explode upward into a jump with arms overhead.',
      'Land softly and flow into the next rep.',
    ],
    notes:
        'Step-back burpees are fine for beginners. Keep core tight in the plank to protect the lower back.',
  ),
  'bike_intervals': ExerciseGuide(
    steps: [
      'Adjust seat height so knee has a slight bend at bottom of pedal stroke.',
      'Pedal easy for 2–3 minutes to warm up.',
      'Increase resistance and cadence for the work interval.',
      'Ease off during rest intervals and repeat.',
    ],
    notes:
        'Indoor bike or assault bike both work. Push hard on work intervals but stay seated if form gets sloppy standing.',
  ),
  'jump_rope': ExerciseGuide(
    steps: [
      'Hold rope handles at hip height, elbows close to ribs.',
      'Jump on the balls of your feet with small, quick hops.',
      'Turn the rope with wrists, not whole arms.',
      'Maintain a steady rhythm for the prescribed time.',
    ],
    notes:
        'Start with single unders before double unders. Jump just high enough for the rope to pass under.',
  ),
  'farmer_carry': ExerciseGuide(
    steps: [
      'Pick up a heavy dumbbell or kettlebell in each hand at your sides.',
      'Stand tall, shoulders packed down, core braced.',
      'Walk with short, controlled steps for the prescribed time or distance.',
      'Set weights down with a hip hinge — don\'t round your back.',
    ],
    notes:
        'Grip and core challenge in one. Keep weights off your thighs as you walk; don\'t lean to either side.',
  ),
  'dynamic_warmup': ExerciseGuide(
    steps: [
      'Begin with 1–2 minutes of light marching or jogging in place.',
      'Flow through leg swings, arm circles, hip openers, and bodyweight squats.',
      'Gradually increase range and speed of each movement.',
      'Finish with a few short acceleration strides or sport-specific moves.',
    ],
    notes:
        'Never skip the warm-up before power or speed work. Move until you feel loose, not exhausted.',
  ),
  'hip_mobility': ExerciseGuide(
    steps: [
      'Perform 90/90 hip switches, leg swings, and deep squat holds.',
      'Move slowly through each position, breathing into tight areas.',
      'Complete the circuit for the prescribed rounds.',
      'Finish with gentle walking to reset.',
    ],
    notes:
        'Mobility should feel like productive tension, not sharp pain. Consistency beats forcing extreme ranges.',
  ),
  'spinal_hang': ExerciseGuide(
    steps: [
      'Grab a pull-up bar or sturdy overhead bar with an overhand grip.',
      'Let your body hang freely, relaxing shoulders and breathing deeply.',
      'Keep a slight bend in elbows if straight-arm hang is uncomfortable.',
      'Release after the prescribed time and stand up slowly.',
    ],
    notes:
        'Decompresses the spine after training. Skip if you have shoulder instability or acute shoulder pain.',
  ),
  'cobra_stretch': ExerciseGuide(
    steps: [
      'Lie face down with hands under shoulders, elbows bent.',
      'Press through hands to lift chest off the floor, hips stay down.',
      'Open chest forward and up, lengthening through the spine.',
      'Hold, breathe, then lower gently.',
    ],
    notes:
        'Keep shoulders away from ears. Reduce height if you feel pinching in the lower back.',
  ),
  'foam_roll': ExerciseGuide(
    steps: [
      'Target major muscle groups: calves, quads, glutes, upper back.',
      'Roll slowly, pausing 20–30 seconds on tender spots.',
      'Avoid rolling directly on joints or the lower back.',
      'Spend roughly equal time on left and right sides.',
    ],
    notes:
        'Foam rolling aids recovery, not performance mid-workout. Light pressure is enough — pain is not the goal.',
  ),
  'yoga_flow': ExerciseGuide(
    steps: [
      'Move through sun salutations or a simple athlete flow: downward dog, lunge, twist, forward fold.',
      'Link breath to movement — inhale on expansions, exhale on folds.',
      'Hold key poses 3–5 breaths where you feel tight.',
      'Finish in a comfortable seated or lying rest.',
    ],
    notes:
        'Recovery day work should feel restorative. Use blocks or modify poses if hamstrings or hips are tight.',
  ),
  'mountain_climbers': ExerciseGuide(
    steps: [
      'Start in a high plank, hands under shoulders, core tight.',
      'Drive one knee toward chest, then quickly switch legs.',
      'Keep hips level and shoulders stacked over wrists.',
      'Maintain a steady pace for the work interval.',
    ],
    notes:
        'Slow down if hips bounce up and down. Shoulders should not drift forward past hands.',
  ),
  'plank_variations': ExerciseGuide(
    steps: [
      'Begin in a forearm or high plank with a straight line from head to heels.',
      'Try variations: shoulder taps, side plank, or plank with leg lifts.',
      'Hold each variation for the prescribed time.',
      'Rest briefly between variations if needed.',
    ],
    notes:
        'Squeeze glutes and quads to protect the lower back. Quality holds beat shaking through bad form.',
  ),
  'medicine_ball_rotational': ExerciseGuide(
    steps: [
      'Stand sideways to a wall, feet shoulder-width apart, holding a med ball at your hip.',
      'Rotate hips and torso, throwing the ball into the wall.',
      'Catch the rebound, absorb with hips, and load for the next throw.',
      'Complete all reps on one side before switching.',
    ],
    notes:
        'Power comes from the ground up through hip rotation. Start with a light ball and short distance from the wall.',
  ),
  'step_ups': ExerciseGuide(
    steps: [
      'Stand facing a box or bench at knee height or slightly below.',
      'Place one full foot on the box, drive through that heel to stand on top.',
      'Bring the trailing foot up without pushing off the back toes excessively.',
      'Step down under control and repeat, then switch legs.',
    ],
    notes:
        'The box should not be so high that your knee passes well above hip height. Keep torso upright throughout.',
  ),
  'band_lateral_walks': ExerciseGuide(
    steps: [
      'Place a mini band around ankles or just above knees.',
      'Sink into a quarter squat with feet hip-width apart.',
      'Step laterally, keeping tension on the band — don\'t let feet click together.',
      'Take prescribed steps one direction, then return the other way.',
    ],
    notes:
        'Glute medius activation for lateral sports. Stay low — if you stand up, the band loses tension.',
  ),
  'calf_raises': ExerciseGuide(
    steps: [
      'Stand on flat ground or the edge of a step with balls of feet on the edge.',
      'Rise up onto toes as high as possible, pausing at the top.',
      'Lower slowly to full stretch at the bottom.',
      'Repeat for prescribed reps; use a wall for balance if needed.',
    ],
    notes:
        'Critical for jumping and running sports. Full range — all the way up, all the way down — matters most.',
  ),
};

ExerciseGuide guideForExercise(TrainingExercise exercise) {
  final isGym = exercise.id.startsWith('gym_');
  return exerciseGuides[exercise.id] ??
      gymExerciseGuides[exercise.id] ??
      ExerciseGuide.fallback(exercise.name, gym: isGym);
}

String focusLabel(TrainingFocus focus) {
  switch (focus) {
    case TrainingFocus.power:
      return 'Power';
    case TrainingFocus.agility:
      return 'Agility';
    case TrainingFocus.strength:
      return 'Strength';
    case TrainingFocus.speed:
      return 'Speed';
    case TrainingFocus.endurance:
      return 'Endurance';
    case TrainingFocus.recovery:
      return 'Recovery';
    case TrainingFocus.mixed:
      return 'Mixed';
  }
}
