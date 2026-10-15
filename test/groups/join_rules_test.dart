import 'package:flutter_test/flutter_test.dart';
import 'package:selah/features/groups/domain/group_models.dart';

void main() {
  test('AuthSession has at most one membership', () {
    const user = SelahUser(
      id: 'u1',
      email: 'a@example.com',
      displayName: 'Ada',
    );
    const membership = GroupMembership(
      role: 'member',
      groupId: 'g1',
      groupName: 'Morning',
      inviteCode: 'ABCD1234',
      churchId: 'c1',
      churchName: 'First',
    );
    const session = AuthSession(
      token: 't',
      user: user,
      membership: membership,
    );
    expect(session.membership, isNotNull);
    expect(
      session.copyWith(clearMembership: true).membership,
      isNull,
    );
  });
}
