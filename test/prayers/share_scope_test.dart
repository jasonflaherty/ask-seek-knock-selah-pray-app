import 'package:flutter_test/flutter_test.dart';
import 'package:selah/features/prayers/domain/share_scope.dart';

void main() {
  test('storage round-trip', () {
    for (final scope in ShareScope.values) {
      expect(ShareScopeX.fromStorage(scope.storageValue), scope);
    }
  });

  test('legacy shared maps to church', () {
    expect(ShareScopeX.fromLegacyShared(true), ShareScope.church);
    expect(ShareScopeX.fromLegacyShared(false), ShareScope.justMe);
  });

  test('labels for editor', () {
    expect(ShareScope.justMe.label, 'Just me');
    expect(ShareScope.group.label, 'Group');
    expect(ShareScope.church.label, 'Church');
  });
}
