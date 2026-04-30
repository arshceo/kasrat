import 'package:kasrat_ai/core/models/exercise_type.dart';

class ExerciseSet {
  final String name;
  final int targetReps;
  final int? targetSeconds;
  final ExerciseType type;
  final bool isHold;
  final int setIndex;
  final int totalSets;
  
  int? actualReps;
  Duration? timeToComplete;
  Duration? restTakenAfter;
  bool isComplete;

  ExerciseSet({
    required this.name,
    required this.targetReps,
    this.targetSeconds,
    required this.type,
    this.isHold = false,
    required this.setIndex,
    required this.totalSets,
    this.actualReps,
    this.timeToComplete,
    this.restTakenAfter,
    this.isComplete = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'targetReps': targetReps,
    'targetSeconds': targetSeconds,
    'type': type.index,
    'isHold': isHold,
    'setIndex': setIndex,
    'totalSets': totalSets,
    'actualReps': actualReps,
    'timeToComplete': timeToComplete?.inSeconds,
    'restTakenAfter': restTakenAfter?.inSeconds,
    'isComplete': isComplete,
  };

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => ExerciseSet(
    name: json['name'],
    targetReps: json['targetReps'],
    targetSeconds: json['targetSeconds'],
    type: ExerciseType.values[json['type']],
    isHold: json['isHold'] ?? false,
    setIndex: json['setIndex'] ?? 0,
    totalSets: json['totalSets'] ?? 1,
    actualReps: json['actualReps'],
    timeToComplete: json['timeToComplete'] != null ? Duration(seconds: json['timeToComplete']) : null,
    restTakenAfter: json['restTakenAfter'] != null ? Duration(seconds: json['restTakenAfter']) : null,
    isComplete: json['isComplete'] ?? false,
  );
}
