import crypto from 'crypto';
import nodemailer from 'nodemailer';
import { query, withClient } from './db.js';

const CODE_TTL_MS = 10 * 60 * 1000;
const SESSION_TTL_MS = 30 * 24 * 60 * 60 * 1000;
const CODE_COOLDOWN_MS = 60 * 1000;

function hash(value) {
  const secret = process.env.TOKEN_SECRET || 'dev-secret';
  return crypto.createHmac('sha256', secret).update(value).digest('hex');
}

function randomCode() {
  return String(crypto.randomInt(100000, 999999));
}

function randomToken() {
  return crypto.randomBytes(32).toString('hex');
}

function inviteCode() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let out = '';
  for (let i = 0; i < 8; i++) {
    out += alphabet[crypto.randomInt(alphabet.length)];
  }
  return out;
}

let transporter;

function mailer() {
  if (transporter) return transporter;
  const host = process.env.SMTP_HOST;
  if (!host) {
    transporter = {
      sendMail: async (opts) => {
        console.log('[dev mail]', opts.to, opts.text);
        return { messageId: 'dev' };
      },
    };
    return transporter;
  }
  transporter = nodemailer.createTransport({
    host,
    port: Number(process.env.SMTP_PORT || 587),
    secure: false,
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });
  return transporter;
}

export function normalizeEmail(email) {
  return String(email || '')
    .trim()
    .toLowerCase();
}

export function mapMembership(row) {
  return {
    role: row.role,
    groupId: row.group_id,
    groupName: row.group_name,
    inviteCode: row.role === 'owner' ? row.invite_code : '',
    churchId: row.church_id,
    churchName: row.church_name,
  };
}

export async function requestLoginCode(emailRaw) {
  const email = normalizeEmail(emailRaw);
  if (!email || !email.includes('@')) {
    const err = new Error('Enter a valid email address.');
    err.status = 400;
    throw err;
  }

  const recent = await query(
    `SELECT created_at FROM login_codes
     WHERE email = $1 AND created_at > now() - interval '1 minute'
     ORDER BY created_at DESC LIMIT 1`,
    [email],
  );
  if (recent.rows.length) {
    const err = new Error('Wait a minute before requesting another code.');
    err.status = 429;
    throw err;
  }

  const code = randomCode();
  const expires = new Date(Date.now() + CODE_TTL_MS);
  await query(
    `INSERT INTO login_codes (email, code_hash, expires_at)
     VALUES ($1, $2, $3)`,
    [email, hash(code), expires.toISOString()],
  );

  const from = process.env.SMTP_FROM || 'Selah <noreply@localhost>';
  try {
    await mailer().sendMail({
      from,
      to: email,
      subject: 'Your Selah sign-in code',
      text: `Your Selah sign-in code is ${code}. It expires in 10 minutes.`,
    });
  } catch (e) {
    const raw = String(e?.message || e || '');
    const authFail =
      /\b535\b/i.test(raw) || /incorrect authentication/i.test(raw);
    const err = new Error(
      authFail
        ? 'Mail login failed. Check SMTP_USER and SMTP_PASS on the server.'
        : 'Could not send the sign-in email. Try again later.',
    );
    err.status = 502;
    throw err;
  }

  return { ok: true, cooldownMs: CODE_COOLDOWN_MS };
}

export async function verifyLoginCode(emailRaw, codeRaw) {
  const email = normalizeEmail(emailRaw);
  const code = String(codeRaw || '').trim();
  if (!email || !code) {
    const err = new Error('Email and code are required.');
    err.status = 400;
    throw err;
  }

  const { rows } = await query(
    `SELECT id FROM login_codes
     WHERE email = $1 AND code_hash = $2 AND expires_at > now()
     ORDER BY created_at DESC LIMIT 1`,
    [email, hash(code)],
  );
  if (!rows.length) {
    const err = new Error('That code is wrong or expired.');
    err.status = 401;
    throw err;
  }

  await query('DELETE FROM login_codes WHERE email = $1', [email]);

  let user;
  const existing = await query('SELECT * FROM users WHERE email = $1', [email]);
  if (existing.rows.length) {
    user = existing.rows[0];
  } else {
    const inserted = await query(
      `INSERT INTO users (email) VALUES ($1) RETURNING *`,
      [email],
    );
    user = inserted.rows[0];
  }

  const token = randomToken();
  const expires = new Date(Date.now() + SESSION_TTL_MS);
  await query(
    `INSERT INTO sessions (user_id, token_hash, expires_at)
     VALUES ($1, $2, $3)`,
    [user.id, hash(token), expires.toISOString()],
  );

  return { token, user, expiresAt: expires.toISOString() };
}

export async function userFromToken(token) {
  if (!token) return null;
  const { rows } = await query(
    `SELECT u.* FROM sessions s
     JOIN users u ON u.id = s.user_id
     WHERE s.token_hash = $1 AND s.expires_at > now()`,
    [hash(token)],
  );
  return rows[0] || null;
}

export async function revokeToken(token) {
  if (!token) return;
  await query('DELETE FROM sessions WHERE token_hash = $1', [hash(token)]);
}

export async function getMemberships(userId) {
  const { rows } = await query(
    `SELECT m.role, m.group_id, m.joined_at,
            g.name AS group_name, g.invite_code, g.church_id,
            c.name AS church_name
     FROM memberships m
     JOIN groups g ON g.id = m.group_id
     JOIN churches c ON c.id = g.church_id
     WHERE m.user_id = $1
     ORDER BY m.joined_at ASC`,
    [userId],
  );
  return rows;
}

/** @deprecated use getMemberships — kept for single-group lookups by group id */
export async function getMembership(userId, groupId) {
  if (!groupId) {
    const rows = await getMemberships(userId);
    return rows[0] || null;
  }
  const { rows } = await query(
    `SELECT m.role, m.group_id, m.joined_at,
            g.name AS group_name, g.invite_code, g.church_id,
            c.name AS church_name
     FROM memberships m
     JOIN groups g ON g.id = m.group_id
     JOIN churches c ON c.id = g.church_id
     WHERE m.user_id = $1 AND m.group_id = $2`,
    [userId, groupId],
  );
  return rows[0] || null;
}

export async function setDisplayName(userId, name) {
  const displayName = String(name || '')
    .trim()
    .replace(/\s+/g, ' ')
    .slice(0, 80);
  if (!displayName) {
    const err = new Error('Enter a short name.');
    err.status = 400;
    throw err;
  }
  const { rows } = await query(
    `UPDATE users SET display_name = $2, updated_at = now()
     WHERE id = $1 RETURNING *`,
    [userId, displayName],
  );
  return rows[0];
}

async function assertNoMembership(userId) {
  const existing = await getMemberships(userId);
  if (existing.length) {
    const err = new Error(
      'You already belong to a group. Leave it before creating or joining another.',
    );
    err.status = 409;
    throw err;
  }
}

export async function createGroup({ userId, churchName, groupName }) {
  const church = String(churchName || '').trim().slice(0, 120);
  const group = String(groupName || '').trim().slice(0, 120);
  if (!church || !group) {
    const err = new Error('Church name and group name are required.');
    err.status = 400;
    throw err;
  }

  await assertNoMembership(userId);

  await withClient(async (client) => {
    await client.query('BEGIN');
    try {
      const c = await client.query(
        `INSERT INTO churches (name) VALUES ($1) RETURNING *`,
        [church],
      );
      let code = inviteCode();
      let g;
      for (let i = 0; i < 5; i++) {
        try {
          g = await client.query(
            `INSERT INTO groups (church_id, name, invite_code)
             VALUES ($1, $2, $3) RETURNING *`,
            [c.rows[0].id, group, code],
          );
          break;
        } catch (e) {
          if (e.code === '23505') {
            code = inviteCode();
            continue;
          }
          throw e;
        }
      }
      if (!g) {
        throw new Error('Could not create a unique invite code.');
      }
      await client.query(
        `INSERT INTO memberships (user_id, group_id, role)
         VALUES ($1, $2, 'owner')`,
        [userId, g.rows[0].id],
      );
      await client.query('COMMIT');
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    }
  });
  return getMemberships(userId);
}

export async function requestJoinGroup({ userId, inviteCodeRaw }) {
  const user = await query('SELECT * FROM users WHERE id = $1', [userId]);
  if (!user.rows.length || !String(user.rows[0].display_name || '').trim()) {
    const err = new Error('Set a short display name before asking to join.');
    err.status = 400;
    throw err;
  }

  const code = String(inviteCodeRaw || '')
    .trim()
    .toUpperCase();
  const { rows } = await query(
    `SELECT * FROM groups WHERE invite_code = $1`,
    [code],
  );
  if (!rows.length) {
    const err = new Error('That invite code was not found.');
    err.status = 404;
    throw err;
  }
  const group = rows[0];

  const existingHere = await getMembership(userId, group.id);
  if (existingHere) {
    const err = new Error('You already belong to this group.');
    err.status = 409;
    throw err;
  }

  await assertNoMembership(userId);

  const pending = await query(
    `SELECT id FROM join_requests
     WHERE group_id = $1 AND user_id = $2 AND status = 'pending'`,
    [group.id, userId],
  );
  if (pending.rows.length) {
    return {
      status: 'pending',
      groupId: group.id,
      groupName: group.name,
    };
  }

  await query(
    `INSERT INTO join_requests (group_id, user_id, status)
     VALUES ($1, $2, 'pending')`,
    [group.id, userId],
  );

  return {
    status: 'pending',
    groupId: group.id,
    groupName: group.name,
  };
}

export async function listPendingJoinRequests(userId) {
  const { rows } = await query(
    `SELECT jr.id, jr.group_id, jr.user_id, jr.created_at,
            u.email, u.display_name,
            g.name AS group_name
     FROM join_requests jr
     JOIN memberships m ON m.group_id = jr.group_id AND m.user_id = $1
     JOIN users u ON u.id = jr.user_id
     JOIN groups g ON g.id = jr.group_id
     WHERE m.role = 'owner' AND jr.status = 'pending'
     ORDER BY jr.created_at ASC`,
    [userId],
  );
  return rows.map((r) => ({
    id: r.id,
    groupId: r.group_id,
    groupName: r.group_name,
    userId: r.user_id,
    email: r.email,
    displayName: r.display_name,
    createdAt: r.created_at,
  }));
}

export async function listMyJoinRequests(userId) {
  const { rows } = await query(
    `SELECT jr.id, jr.group_id, jr.status, jr.created_at,
            g.name AS group_name, c.name AS church_name
     FROM join_requests jr
     JOIN groups g ON g.id = jr.group_id
     JOIN churches c ON c.id = g.church_id
     WHERE jr.user_id = $1 AND jr.status = 'pending'
     ORDER BY jr.created_at ASC`,
    [userId],
  );
  return rows.map((r) => ({
    id: r.id,
    groupId: r.group_id,
    groupName: r.group_name,
    churchName: r.church_name,
    status: r.status,
    createdAt: r.created_at,
  }));
}

export async function listGroupMembers(userId, groupId) {
  const membership = await getMembership(userId, groupId);
  if (!membership || membership.role !== 'owner') {
    const err = new Error('Only the group owner can see the member list.');
    err.status = 403;
    throw err;
  }
  const { rows } = await query(
    `SELECT u.id, u.email, u.display_name, m.role, m.joined_at
     FROM memberships m
     JOIN users u ON u.id = m.user_id
     WHERE m.group_id = $1
     ORDER BY m.role DESC, m.joined_at ASC`,
    [groupId],
  );
  return rows.map((r) => ({
    userId: r.id,
    email: r.email,
    displayName: r.display_name,
    role: r.role,
    joinedAt: r.joined_at,
  }));
}

export async function resolveJoinRequest({
  ownerUserId,
  requestId,
  allow,
}) {
  const { rows } = await query(
    `SELECT jr.*, g.name AS group_name
     FROM join_requests jr
     JOIN groups g ON g.id = jr.group_id
     WHERE jr.id = $1`,
    [requestId],
  );
  if (!rows.length) {
    const err = new Error('That request was not found.');
    err.status = 404;
    throw err;
  }
  const request = rows[0];
  if (request.status !== 'pending') {
    const err = new Error('That request was already decided.');
    err.status = 409;
    throw err;
  }

  const ownership = await getMembership(ownerUserId, request.group_id);
  if (!ownership || ownership.role !== 'owner') {
    const err = new Error('Only the group owner can decide this request.');
    err.status = 403;
    throw err;
  }

  if (!allow) {
    await query(
      `UPDATE join_requests
       SET status = 'denied', resolved_at = now()
       WHERE id = $1`,
      [requestId],
    );
    return { status: 'denied', groupId: request.group_id };
  }

  const already = await getMembership(request.user_id, request.group_id);
  if (already) {
    await query(
      `UPDATE join_requests
       SET status = 'allowed', resolved_at = now()
       WHERE id = $1`,
      [requestId],
    );
    return { status: 'allowed', groupId: request.group_id };
  }

  const elsewhere = await getMemberships(request.user_id);
  if (elsewhere.length) {
    const err = new Error(
      'That person already belongs to another group.',
    );
    err.status = 409;
    throw err;
  }

  await withClient(async (client) => {
    await client.query('BEGIN');
    try {
      await client.query(
        `INSERT INTO memberships (user_id, group_id, role)
         VALUES ($1, $2, 'member')`,
        [request.user_id, request.group_id],
      );
      await client.query(
        `UPDATE join_requests
         SET status = 'allowed', resolved_at = now()
         WHERE id = $1`,
        [requestId],
      );
      await client.query('COMMIT');
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    }
  });

  return { status: 'allowed', groupId: request.group_id };
}

export async function removeMember({ ownerUserId, groupId, memberUserId }) {
  const ownership = await getMembership(ownerUserId, groupId);
  if (!ownership || ownership.role !== 'owner') {
    const err = new Error('Only the group owner can remove a member.');
    err.status = 403;
    throw err;
  }
  if (memberUserId === ownerUserId) {
    const err = new Error('You cannot remove yourself. Delete the group instead.');
    err.status = 409;
    throw err;
  }
  const target = await getMembership(memberUserId, groupId);
  if (!target) {
    const err = new Error('That person is not in this group.');
    err.status = 404;
    throw err;
  }
  await query(
    `DELETE FROM memberships WHERE user_id = $1 AND group_id = $2`,
    [memberUserId, groupId],
  );
}

export async function leaveGroup(userId, groupId) {
  const membership = await getMembership(userId, groupId);
  if (!membership) {
    const err = new Error('You are not in that group.');
    err.status = 404;
    throw err;
  }
  if (membership.role === 'owner') {
    const err = new Error(
      'The owner must delete the group, or ask the server admin to appoint a new owner first.',
    );
    err.status = 409;
    throw err;
  }
  await query(
    `DELETE FROM memberships WHERE user_id = $1 AND group_id = $2`,
    [userId, groupId],
  );
  return getMemberships(userId);
}

export async function deleteGroup(userId, groupId) {
  const membership = await getMembership(userId, groupId);
  if (!membership || membership.role !== 'owner') {
    const err = new Error('Only the group owner can delete the group.');
    err.status = 403;
    throw err;
  }
  // Delete only this group. Keep the church row if other groups share it
  // (today each create makes its own church, but stay safe).
  const churchId = membership.church_id;
  await query('DELETE FROM groups WHERE id = $1', [groupId]);
  const remaining = await query(
    `SELECT id FROM groups WHERE church_id = $1`,
    [churchId],
  );
  if (!remaining.rows.length) {
    await query('DELETE FROM churches WHERE id = $1', [churchId]);
  }
  return getMemberships(userId);
}

export { inviteCode, hash };
