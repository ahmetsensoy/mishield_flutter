import '../config/remote_app_config.dart';

/// Compares semantic versions like `1.2.3` (build suffix `+123` is ignored).
abstract final class VersionGate {
  static String normalize(String raw) {
    final v = raw.trim();
    final plus = v.indexOf('+');
    return plus >= 0 ? v.substring(0, plus) : v;
  }

  /// `< 0` if [a] < [b], `0` if equal, `> 0` if [a] > [b].
  static int compareSemver(String a, String b) {
    final pa = _parts(normalize(a));
    final pb = _parts(normalize(b));
    for (var i = 0; i < 3; i++) {
      if (pa[i] != pb[i]) return pa[i].compareTo(pb[i]);
    }
    return 0;
  }

  static List<int> _parts(String v) {
    final bits = v.split('.');
    int at(int i) {
      if (i >= bits.length) return 0;
      final s = bits[i].trim();
      final n = int.tryParse(s);
      return n ?? 0;
    }

    return [at(0), at(1), at(2)];
  }

  /// True when the installed app is **older than** the minimum required by remote config.
  static bool mustBlock(String appVersion, RemoteAppConfig? remote) {
    final min = remote?.minSupportedVersion;
    if (min == null || min.isEmpty) return false;
    return compareSemver(appVersion, min) < 0;
  }
}
