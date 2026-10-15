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
  await mailer().sendMail({
    from,
    to: email,
    subject: 'Your Selah sign-in code',
    text: `Your Selah sign-in code is ${code}. It expires in 10 minutes.`,
  });

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

export async function getMembership(userId) {
  const { rows } = await query(
    `SELECT m.role, m.group_id, m.joined_at,
            g.name AS group_name, g.invite_code, g.church_id,
            c.name AS church_name
     FROM memberships m
     JOIN groups g ON g.id = m.group_id
     JOIN churches c ON c.id = g.church_id
     WHERE m.user_id = $1`,
    [userId],
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

export async function createGroup({ userId, churchName, groupName }) {
  const membership = await getMembership(userId);
  if (membership) {
    const err = new Error('You already belong to a group.');
    err.status = 409;
    throw err;
  }
  const church = String(churchName || '').trim().slice(0, 120);
  const group = String(groupName || '').trim().slice(0, 120);
  if (!church || !group) {
    const err = new Error('Church name and group name are required.');
    err.status = 400;
    throw err;
  }

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
  return getMembership(userId);
}

export async function joinGroup({ userId, inviteCodeRaw }) {
  const membership = await getMembership(userId);
  if (membership) {
    const err = new Error('You already belong to a group.');
    err.status = 409;
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
  await query(
    `INSERT INTO memberships (user_id, group_id, role)
     VALUES ($1, $2, 'member')`,
    [userId, rows[0].id],
  );
  return getMembership(userId);
}

export async function leaveGroup(userId) {
  const membership = await getMembership(userId);
  if (!membership) {
    const err = new Error('You are not in a group.');
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
  await query('DELETE FROM memberships WHERE user_id = $1', [userId]);
}

export async function deleteGroup(userId) {
  const membership = await getMembership(userId);
  if (!membership || membership.role !== 'owner') {
    const err = new Error('Only the group owner can delete the group.');
    err.status = 403;
    throw err;
  }
  const churchId = membership.church_id;
  await query('DELETE FROM churches WHERE id = $1', [churchId]);
}

export { inviteCode, hash };
