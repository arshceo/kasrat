class ChallengeBlueprint {
  final String protocolName;
  final String difficultyTag;
  final String systemRationale;
  final List<String> coreArsenal;
  final List<Map<String, String>> roadmapPhases;
  final List<String> guaranteedOutcomes;
  final String tag;

  ChallengeBlueprint({
    required this.protocolName,
    required this.difficultyTag,
    required this.systemRationale,
    required this.coreArsenal,
    required this.roadmapPhases,
    required this.guaranteedOutcomes,
    required this.tag,
  });

  factory ChallengeBlueprint.fromJson(Map<String, dynamic> json) {
    return ChallengeBlueprint(
      protocolName: json['protocolName'] ?? '',
      difficultyTag: json['difficultyTag'] ?? '',
      systemRationale: json['systemRationale'] ?? '',
      coreArsenal: List<String>.from(json['coreArsenal'] ?? []),
      roadmapPhases: (json['roadmapPhases'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          [],
      guaranteedOutcomes: List<String>.from(json['guaranteedOutcomes'] ?? []),
      tag: json['tag'] ?? 'STRENGTH',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'protocolName': protocolName,
      'difficultyTag': difficultyTag,
      'systemRationale': systemRationale,
      'coreArsenal': coreArsenal,
      'roadmapPhases': roadmapPhases,
      'guaranteedOutcomes': guaranteedOutcomes,
      'tag': tag,
    };
  }
}

class DailyMission {
  final String dayTitle;
  final String frameworkType;
  final String aiFeedback;
  final List<String> exercises;
  final String dailyStructure;
  final int targetReps;

  DailyMission({
    required this.dayTitle,
    required this.frameworkType,
    required this.aiFeedback,
    required this.exercises,
    required this.dailyStructure,
    required this.targetReps,
  });

  factory DailyMission.fromJson(Map<String, dynamic> json) {
    return DailyMission(
      dayTitle: json['dayTitle'] ?? '',
      frameworkType: json['frameworkType'] ?? '',
      aiFeedback: json['aiFeedback'] ?? '',
      exercises: List<String>.from(json['exercises'] ?? []),
      dailyStructure: json['dailyStructure'] ?? '',
      targetReps: json['targetReps'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayTitle': dayTitle,
      'frameworkType': frameworkType,
      'aiFeedback': aiFeedback,
      'exercises': exercises,
      'dailyStructure': dailyStructure,
      'targetReps': targetReps,
    };
  }
}
