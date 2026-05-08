import 'package:flutter_test/flutter_test.dart';

import 'package:mishield_flutter/config/remote_app_config.dart';
import 'package:mishield_flutter/services/version_gate.dart';

void main() {
  test('mustBlock when below min', () {
    final remote = RemoteAppConfig(minSupportedVersion: '2.0.0');
    expect(VersionGate.mustBlock('1.9.9', remote), isTrue);
    expect(VersionGate.mustBlock('2.0.0', remote), isFalse);
    expect(VersionGate.mustBlock('2.0.1', remote), isFalse);
  });

  test('mustBlock when remote missing min', () {
    expect(VersionGate.mustBlock('0.0.1', const RemoteAppConfig()), isFalse);
  });

  test('normalize strips build metadata', () {
    expect(VersionGate.normalize('1.0.0+99'), '1.0.0');
  });
}
