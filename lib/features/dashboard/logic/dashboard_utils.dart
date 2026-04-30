class DashboardUtils {
  static String getInsigniaPath(String league) {
    final l = league.toLowerCase();
    if (l.contains('black ops')) return 'assets/images/black_ops.png';
    if (l.contains('commando')) return 'assets/images/commando.png';
    if (l.contains('soldier')) return 'assets/images/soldier.png';
    return 'assets/images/recruit.png';
  }
}
