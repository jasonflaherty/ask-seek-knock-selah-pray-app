-- Allow one person in many groups. Invite code requests wait for owner approval.

ALTER TABLE memberships DROP CONSTRAINT memberships_pkey;

ALTER TABLE memberships
  ADD PRIMARY KEY (user_id, group_id);

CREATE TABLE join_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('pending', 'allowed', 'denied')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  resolved_at TIMESTAMPTZ
);

-- At most one pending request per person per group.
CREATE UNIQUE INDEX join_requests_one_pending
  ON join_requests (group_id, user_id)
  WHERE status = 'pending';

CREATE INDEX join_requests_group_pending_idx
  ON join_requests (group_id)
  WHERE status = 'pending';

CREATE INDEX join_requests_user_idx ON join_requests (user_id);
