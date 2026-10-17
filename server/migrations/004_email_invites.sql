-- Owner-sent email invites: pre-approve that address for a group.

CREATE TABLE email_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  invited_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'revoked')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL,
  accepted_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX email_invites_one_pending
  ON email_invites (group_id, email)
  WHERE status = 'pending';

CREATE INDEX email_invites_email_pending_idx
  ON email_invites (email)
  WHERE status = 'pending';
