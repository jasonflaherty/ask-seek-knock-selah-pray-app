import 'package:flutter_test/flutter_test.dart';
import 'package:selah/features/groups/domain/group_models.dart';

void main() {
  test('AuthSession can hold more than one membership', () {
    const user = SelahUser(
      id: 'u1',
      email: 'a@example.com',
      displayName: 'Ada',
    );
    const morning = GroupMembership(
      role: 'owner',
      groupId: 'g1',
      groupName: 'Morning',
      inviteCode: 'ABCD1234',
      churchId: 'c1',
      churchName: 'First',
    );
    const evening = GroupMembership(
      role: 'member',
      groupId: 'g2',
      groupName: 'Evening',
      inviteCode: '',
      churchId: 'c2',
      churchName: 'Second',
    );
    const session = AuthSession(
      token: 't',
      user: user,
      memberships: [morning, evening],
    );
    expect(session.hasGroup, isTrue);
    expect(session.memberships, hasLength(2));
    expect(session.membershipFor('g1')?.isOwner, isTrue);
    expect(session.membershipFor('g2')?.isOwner, isFalse);
    expect(session.membership?.groupId, 'g1');
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
