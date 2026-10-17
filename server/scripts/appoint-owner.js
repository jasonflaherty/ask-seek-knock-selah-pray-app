#!/usr/bin/env node
/**
 * Appoint a new group owner from the VPS.
 *
 * Usage:
 *   node scripts/appoint-owner.js --group-id <uuid> --email person@example.com
 *
 * The person must already have signed in at least once (user row exists),
 * or this script creates the user and membership. One group per person:
 * they must not already belong to a different group.
 */
import { query, closePool, migrate, withClient } from '../src/db.js';
import { normalizeEmail } from '../src/auth.js';

function arg(name) {
  const i = process.argv.indexOf(name);
  if (i === -1 || !process.argv[i + 1]) return null;
  return process.argv[i + 1];
}

const groupId = arg('--group-id');
const emailRaw = arg('--email');

if (!groupId || !emailRaw) {
  console.error(
    'Usage: node scripts/appoint-owner.js --group-id <uuid> --email <email>',
  );
  process.exit(1);
}

await migrate();

const email = normalizeEmail(emailRaw);
const group = await query('SELECT * FROM groups WHERE id = $1', [groupId]);
if (!group.rows.length) {
  console.error('Group not found.');
  process.exit(1);
}

let user;
const existing = await query('SELECT * FROM users WHERE email = $1', [email]);
if (existing.rows.length) {
  user = existing.rows[0];
} else {
  const inserted = await query(
    `INSERT INTO users (email, display_name) VALUES ($1, $2) RETURNING *`,
    [email, email.split('@')[0]],
  );
  user = inserted.rows[0];
  console.log(`Created user ${email}`);
}

const other = await query(
  `SELECT group_id FROM memberships WHERE user_id = $1 AND group_id <> $2`,
  [user.id, groupId],
);
if (other.rows.length) {
  console.error(
    'That person already belongs to another group. Leave that group first.',
  );
  process.exit(1);
}

await withClient(async (client) => {
  await client.query('BEGIN');
  try {
    await client.query(
      `UPDATE memberships SET role = 'member'
       WHERE group_id = $1 AND role = 'owner'`,
      [groupId],
    );
    await client.query(
      `INSERT INTO memberships (user_id, group_id, role)
       VALUES ($1, $2, 'owner')
       ON CONFLICT (user_id, group_id) DO UPDATE
         SET role = 'owner'`,
      [user.id, groupId],
    );
    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  }
});

console.log(`Owner of group ${groupId} is now ${email}`);
await closePool();
