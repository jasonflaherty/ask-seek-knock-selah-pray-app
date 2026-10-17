import 'package:flutter_test/flutter_test.dart';
import 'package:selah/features/groups/domain/group_models.dart';

void main() {
  test('AuthSession exposes a single membership', () {
    const user = SelahUser(
      id: 'u1',
      email: 'a@example.com',
      displayName: 'Ada',
    );
    const membership = GroupMembership(
      role: 'owner',
      groupId: 'g1',
      groupName: 'Morning',
      inviteCode: 'ABCD1234',
      churchId: 'c1',
      churchName: 'First',
    );
    const session = AuthSession(
      token: 't',
      user: user,
      memberships: [membership],
    );
    expect(session.hasGroup, isTrue);
    expect(session.memberships, hasLength(1));
    expect(session.membership?.groupId, 'g1');
    expect(session.membership?.isOwner, isTrue);
    expect(session.membershipFor('g1')?.groupName, 'Morning');
    expect(session.membershipFor('other'), isNull);
  });

  test('AuthSession with no membership', () {
    const user = SelahUser(
      id: 'u1',
      email: 'a@example.com',
      displayName: 'Ada',
    );
    const session = AuthSession(token: 't', user: user);
    expect(session.hasGroup, isFalse);
    expect(session.membership, isNull);
  });

  test('member invite code is empty on the client model', () {
    const m = GroupMembership(
      role: 'member',
      groupId: 'g1',
      groupName: 'Morning',
      inviteCode: '',
      churchId: 'c1',
      churchName: 'First',
    );
    expect(m.inviteCode, isEmpty);
    expect(m.isOwner, isFalse);
  });
}
