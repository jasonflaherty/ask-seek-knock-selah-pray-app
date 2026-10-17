-- One group per person. Drop extras (keep earliest membership) then unique user_id.

DELETE FROM memberships a
  USING memberships b
 WHERE a.user_id = b.user_id
   AND a.ctid > b.ctid;

CREATE UNIQUE INDEX IF NOT EXISTS memberships_one_per_user
  ON memberships (user_id);
