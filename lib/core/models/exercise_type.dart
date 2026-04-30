enum ExerciseType {
  pushup,
  squat,
  situp,
  plank,
  burpee,
  jumpingJacks,
  wallSit,
  pullup,
  lunge,
  crunch,
  jumpSquat;

  bool get isHold => this == ExerciseType.plank || this == ExerciseType.wallSit;

  // THE SPATIAL INTELLIGENCE LOGIC
  bool get allowsLandscape {
    switch (this) {
      case ExerciseType.pushup:
      case ExerciseType.plank:
      case ExerciseType.situp:
      case ExerciseType.burpee:
      case ExerciseType.crunch:
        return true; // Floor exercises need widescreen
      case ExerciseType.squat:
      case ExerciseType.jumpSquat:
      case ExerciseType.lunge:
      case ExerciseType.wallSit:
      case ExerciseType.jumpingJacks:
      case ExerciseType.pullup:
      default:
        return false; // Standing exercises MUST be portrait
    }
  }

  String get displayName {
    switch (this) {
      case ExerciseType.squat: return 'SQUAT';
      case ExerciseType.pushup: return 'PUSHUP';
      case ExerciseType.plank: return 'PLANK';
      case ExerciseType.jumpSquat: return 'JUMP SQUAT';
      case ExerciseType.lunge: return 'LUNGE';
      case ExerciseType.situp: return 'SITUP';
      case ExerciseType.burpee: return 'BURPEE';
      case ExerciseType.wallSit: return 'WALL SIT';
      case ExerciseType.jumpingJacks: return 'JUMPING JACKS';
      case ExerciseType.pullup: return 'PULLUP';
      case ExerciseType.crunch: return 'CRUNCH';
    }
  }

  String get pluralName {
    switch (this) {
      case ExerciseType.squat: return 'SQUATS';
      case ExerciseType.pushup: return 'PUSHUPS';
      case ExerciseType.plank: return 'PLANKING';
      case ExerciseType.jumpSquat: return 'JUMP SQUATS';
      case ExerciseType.lunge: return 'LUNGES';
      case ExerciseType.situp: return 'SITUPS';
      case ExerciseType.burpee: return 'BURPEES';
      case ExerciseType.wallSit: return 'WALL SITTING';
      default: return displayName.toUpperCase();
    }
  }

  String get dbType {
    switch (this) {
      case ExerciseType.squat: return 'SQUAT';
      case ExerciseType.pushup: return 'PUSHUP';
      case ExerciseType.plank: return 'PLANK';
      case ExerciseType.jumpSquat: return 'JUMP_SQUAT';
      case ExerciseType.situp: return 'SITUP';
      case ExerciseType.lunge: return 'LUNGE';
      case ExerciseType.burpee: return 'BURPEE';
      case ExerciseType.wallSit: return 'WALL_SIT';
      default: return name.toUpperCase();
    }
  }
}
