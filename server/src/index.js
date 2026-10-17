import express from 'express';
import cookieParser from 'cookie-parser';
import path from 'path';
import { fileURLToPath } from 'url';
import { migrate, closePool } from './db.js';
import {
  requestLoginCode,
  verifyLoginCode,
  userFromToken,
  revokeToken,
  setDisplayName,
  createGroup,
  requestJoinGroup,
  leaveGroup,
  deleteGroup,
  getMemberships,
  mapMembership,
  listPendingJoinRequests,
  listMyJoinRequests,
  listGroupMembers,
  resolveJoinRequest,
  removeMember,
} from './auth.js';
import {
  listSharedPrayers,
  upsertSharedPrayer,
  deleteSharedPrayer,
  listNotes,
  upsertNote,
  deleteNote,
} from './prayers.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const app = express();
const PORT = Number(process.env.PORT || 8080);

app.use(express.json({ limit: '1mb' }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

function tokenFromReq(req) {
  const header = req.headers.authorization || '';
  if (header.startsWith('Bearer ')) return header.slice(7);
  return req.cookies?.selah_session || null;
}

async function requireUser(req, res, next) {
  try {
    const user = await userFromToken(tokenFromReq(req));
    if (!user) {
      res.status(401).json({ error: 'Sign in first.' });
      return;
    }
    req.user = user;
    next();
  } catch (err) {
    next(err);
  }
}

function wrapUser(user, memberships) {
  return {
    user: {
      id: user.id,
      email: user.email,
      displayName: user.display_name,
    },
    memberships: (memberships || []).map(mapMembership),
    // Back-compat for older clients: first membership or null.
    membership: memberships?.length ? mapMembership(memberships[0]) : null,
  };
}

function sendUser(res, user, memberships) {
  res.json(wrapUser(user, memberships));
}

app.get('/api/health', (_req, res) => {
  res.json({ ok: true });
});

app.post('/api/auth/request-code', async (req, res, next) => {
  try {
    const result = await requestLoginCode(req.body?.email);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

app.post('/api/auth/verify-code', async (req, res, next) => {
  try {
    const { token, user, expiresAt } = await verifyLoginCode(
      req.body?.email,
      req.body?.code,
    );
    res.cookie('selah_session', token, {
      httpOnly: true,
      sameSite: 'lax',
      secure: process.env.PUBLIC_BASE_URL?.startsWith('https'),
      maxAge: 30 * 24 * 60 * 60 * 1000,
    });
    const memberships = await getMemberships(user.id);
    res.json({ token, expiresAt, ...wrapUser(user, memberships) });
  } catch (err) {
    next(err);
  }
});

app.post('/api/auth/sign-out', async (req, res, next) => {
  try {
    await revokeToken(tokenFromReq(req));
    res.clearCookie('selah_session');
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

app.get('/api/me', requireUser, async (req, res, next) => {
  try {
    const memberships = await getMemberships(req.user.id);
    sendUser(res, req.user, memberships);
  } catch (err) {
    next(err);
  }
});

app.patch('/api/me', requireUser, async (req, res, next) => {
  try {
    const user = await setDisplayName(req.user.id, req.body?.displayName);
    const memberships = await getMemberships(user.id);
    sendUser(res, user, memberships);
  } catch (err) {
    next(err);
  }
});

app.post('/api/groups', requireUser, async (req, res, next) => {
  try {
    const memberships = await createGroup({
      userId: req.user.id,
      churchName: req.body?.churchName,
      groupName: req.body?.groupName,
    });
    sendUser(res, req.user, memberships);
  } catch (err) {
    next(err);
  }
});

app.post('/api/groups/join', requireUser, async (req, res, next) => {
  try {
    const result = await requestJoinGroup({
      userId: req.user.id,
      inviteCodeRaw: req.body?.inviteCode,
    });
    const memberships = await getMemberships(req.user.id);
    const pending = await listMyJoinRequests(req.user.id);
    res.json({
      ...wrapUser(req.user, memberships),
      joinRequest: result,
      pendingJoinRequests: pending,
    });
  } catch (err) {
    next(err);
  }
});

app.post('/api/groups/leave', requireUser, async (req, res, next) => {
  try {
    const groupId = req.body?.groupId;
    if (!groupId) {
      const err = new Error('groupId is required.');
      err.status = 400;
      throw err;
    }
    const memberships = await leaveGroup(req.user.id, groupId);
    sendUser(res, req.user, memberships);
  } catch (err) {
    next(err);
  }
});

app.delete('/api/groups', requireUser, async (req, res, next) => {
  try {
    const groupId = req.body?.groupId || req.query?.groupId;
    if (!groupId) {
      const err = new Error('groupId is required.');
      err.status = 400;
      throw err;
    }
    const memberships = await deleteGroup(req.user.id, groupId);
    sendUser(res, req.user, memberships);
  } catch (err) {
    next(err);
  }
});

app.get('/api/groups/:groupId/members', requireUser, async (req, res, next) => {
  try {
    const members = await listGroupMembers(req.user.id, req.params.groupId);
    res.json({ members });
  } catch (err) {
    next(err);
  }
});

app.delete(
  '/api/groups/:groupId/members/:userId',
  requireUser,
  async (req, res, next) => {
    try {
      await removeMember({
        ownerUserId: req.user.id,
        groupId: req.params.groupId,
        memberUserId: req.params.userId,
      });
      const members = await listGroupMembers(req.user.id, req.params.groupId);
      res.json({ members });
    } catch (err) {
      next(err);
    }
  },
);

app.get('/api/join-requests', requireUser, async (req, res, next) => {
  try {
    const [incoming, mine] = await Promise.all([
      listPendingJoinRequests(req.user.id),
      listMyJoinRequests(req.user.id),
    ]);
    res.json({ incoming, mine });
  } catch (err) {
    next(err);
  }
});

app.post('/api/join-requests/:id/allow', requireUser, async (req, res, next) => {
  try {
    await resolveJoinRequest({
      ownerUserId: req.user.id,
      requestId: req.params.id,
      allow: true,
    });
    const incoming = await listPendingJoinRequests(req.user.id);
    res.json({ ok: true, incoming });
  } catch (err) {
    next(err);
  }
});

app.post('/api/join-requests/:id/deny', requireUser, async (req, res, next) => {
  try {
    await resolveJoinRequest({
      ownerUserId: req.user.id,
      requestId: req.params.id,
      allow: false,
    });
    const incoming = await listPendingJoinRequests(req.user.id);
    res.json({ ok: true, incoming });
  } catch (err) {
    next(err);
  }
});

app.get('/api/prayers', requireUser, async (req, res, next) => {
  try {
    const data = await listSharedPrayers(req.user, {
      scope: req.query.scope,
      groupId: req.query.groupId,
    });
    res.json(data);
  } catch (err) {
    next(err);
  }
});

app.put('/api/prayers/:syncId', requireUser, async (req, res, next) => {
  try {
    const prayer = await upsertSharedPrayer(req.user, {
      ...req.body,
      syncId: req.params.syncId,
    });
    res.json({ prayer });
  } catch (err) {
    next(err);
  }
});

app.delete('/api/prayers/:syncId', requireUser, async (req, res, next) => {
  try {
    await deleteSharedPrayer(req.user, req.params.syncId);
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

app.get('/api/notes', requireUser, async (req, res, next) => {
  try {
    const notes = await listNotes(req.user, { groupId: req.query.groupId });
    res.json({ notes });
  } catch (err) {
    next(err);
  }
});

app.post('/api/notes', requireUser, async (req, res, next) => {
  try {
    const note = await upsertNote(req.user, req.body || {});
    res.json({
      note: {
        id: note.id,
        groupId: note.group_id,
        kind: note.kind,
        body: note.body,
        authorUserId: note.author_user_id,
        authorDisplayName: note.author_display_name,
        createdAt: note.created_at,
        updatedAt: note.updated_at,
      },
    });
  } catch (err) {
    next(err);
  }
});

app.delete('/api/notes/:id', requireUser, async (req, res, next) => {
  try {
    await deleteNote(req.user, req.params.id);
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

app.use((err, _req, res, _next) => {
  const status = err.status || 500;
  if (status >= 500) console.error(err);
  res.status(status).json({ error: err.message || 'Server error' });
});

await migrate();
app.listen(PORT, () => {
  console.log(`selah-api listening on ${PORT}`);
});

async function shutdown() {
  await closePool();
  process.exit(0);
}
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
