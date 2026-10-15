-- Selah shared data: accounts, one group per person, church/group prayers, notes.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE churches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  church_id UUID NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  invite_code TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE memberships (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('owner', 'member')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX memberships_one_owner_per_group
  ON memberships (group_id)
  WHERE role = 'owner';

CREATE TABLE login_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  code_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX login_codes_email_idx ON login_codes (email);

CREATE TABLE sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX sessions_user_idx ON sessions (user_id);

-- share_scope: group | church (just-me never stored here)
CREATE TABLE shared_prayers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sync_id TEXT NOT NULL UNIQUE,
  author_user_id UUID NOT NULL REFERENCES users(id),
  author_display_name TEXT NOT NULL DEFAULT '',
  church_id UUID NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  share_scope TEXT NOT NULL CHECK (share_scope IN ('group', 'church')),
  name TEXT NOT NULL,
  person TEXT NOT NULL DEFAULT '',
  request TEXT NOT NULL,
  is_answered BOOLEAN NOT NULL DEFAULT false,
  answered_at TIMESTAMPTZ,
  answered_note TEXT,
  tags JSONB NOT NULL DEFAULT '[]'::jsonb,
  verse_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
  custom_verses JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT shared_prayers_group_scope CHECK (
    (share_scope = 'group' AND group_id IS NOT NULL)
    OR (share_scope = 'church')
  )
);

CREATE INDEX shared_prayers_church_idx ON shared_prayers (church_id);
CREATE INDEX shared_prayers_group_idx ON shared_prayers (group_id);

CREATE TABLE prayer_tombstones (
  sync_id TEXT PRIMARY KEY,
  church_id UUID NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
  group_id UUID REFERENCES groups(id) ON DELETE SET NULL,
  share_scope TEXT NOT NULL CHECK (share_scope IN ('group', 'church')),
  deleted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE study_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  author_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  author_display_name TEXT NOT NULL DEFAULT '',
  kind TEXT NOT NULL CHECK (kind IN ('current_study', 'other')),
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- At most one current_study note per member in a group.
CREATE UNIQUE INDEX study_notes_one_current
  ON study_notes (group_id, author_user_id)
  WHERE kind = 'current_study';

CREATE INDEX study_notes_group_idx ON study_notes (group_id);
