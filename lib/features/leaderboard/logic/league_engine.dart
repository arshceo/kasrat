class LeagueEngine {
  /// Strictly calculates the rank/league based on physical metrics and challenge wins.
  static String calculateLeague({
    required int pushups,
    required int squats,
    required int situps,
    required int challengesWon,
    bool hasCompletedBaseline = true,
  }) {
    if (!hasCompletedBaseline) return 'UNCLASSIFIED';

    // 0. LEGENDARY (APEX OPERATIVE) Check
    if (pushups >= 200 && squats >= 200 && situps >= 200) {
      return 'Legendary (Apex Operative)';
    }

    // 1. BLACK OPS (OPM PROTOCOL) Check
    if (pushups >= 100 && squats >= 100 && situps >= 100) {
      return 'Black Ops (OPM Protocol)';
    }

    // 2. Commando Hardware Check
    if (pushups >= 60 && squats >= 80 && situps >= 50) {
      if (challengesWon >= 3 || pushups >= 80) return 'Commando';
      return 'Soldier (Commando Candidate)';
    }

    // 3. Soldier Hardware Check
    if (pushups >= 30 && squats >= 40 && situps >= 30) {
      if (challengesWon >= 1 || pushups >= 40) return 'Soldier';
      return 'Recruit (Soldier Candidate)';
    }

    // Default
    return 'Recruit';
  }
}
