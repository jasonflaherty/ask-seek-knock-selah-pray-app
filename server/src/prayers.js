import { query } from './db.js';
import { getMembership } from './auth.js';

function mapPrayer(row) {
  return {
    syncId: row.sync_id,
    shareScope: row.share_scope,
    churchId: row.church_id,
    groupId: row.group_id,
    name: row.name,
    person: row.person,
    request: row.request,
    isAnswered: row.is_answered,
    answeredAt: row.answered_at,
    answeredNote: row.answered_note,
    tags: row.tags || [],
    verseIds: row.verse_ids || [],
    customVerses: row.custom_verses || [],
    authorUserId: row.author_user_id,
    authorDisplayName: row.author_display_name,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export async function listSharedPrayers(user, { scope } = {}) {
  const membership = await getMembership(user.id);
  if (!membership) {
    const err = new Error('Join a group to see shared prayers.');
    err.status = 403;
    throw err;
  }

  let sql = `SELECT * FROM shared_prayers WHERE church_id = $1`;
  const params = [membership.church_id];
  if (scope === 'church') {
    sql += ` AND share_scope = 'church'`;
  } else if (scope === 'group') {
    sql += ` AND share_scope = 'group' AND group_id = $2`;
    params.push(membership.group_id);
  } else {
    sql += ` AND (share_scope = 'church' OR (share_scope = 'group' AND group_id = $2))`;
    params.push(membership.group_id);
  }
  sql += ` ORDER BY updated_at DESC`;

  const { rows } = await query(sql, params);
  const tombs = await query(
    `SELECT sync_id, deleted_at, share_scope, church_id, group_id
     FROM prayer_tombstones
     WHERE church_id = $1`,
    [membership.church_id],
  );
  return {
    prayers: rows.map(mapPrayer),
    tombstones: tombs.rows.map((t) => ({
      syncId: t.sync_id,
      deletedAt: t.deleted_at,
      shareScope: t.share_scope,
      churchId: t.church_id,
      groupId: t.group_id,
    })),
    membership,
  };
}

export async function upsertSharedPrayer(user, body) {
  const membership = await getMembership(user.id);
  if (!membership) {
    const err = new Error('Join a group before sharing a prayer.');
    err.status = 403;
    throw err;
  }

  const shareScope = body.shareScope === 'group' ? 'group' : 'church';
  const syncId = String(body.syncId || '').trim();
  if (!syncId) {
    const err = new Error('syncId is required.');
    err.status = 400;
    throw err;
  }

  const name = String(body.name || '').trim().slice(0, 100);
  const request = String(body.request || '').trim();
  if (!name || !request) {
    const err = new Error('Name and request are required.');
    err.status = 400;
    throw err;
  }

  const groupId = shareScope === 'group' ? membership.group_id : null;
  const displayName = user.display_name || '';
  const person = String(body.person || '').trim().slice(0, 100);
  const tags = Array.isArray(body.tags) ? body.tags : [];
  const verseIds = Array.isArray(body.verseIds) ? body.verseIds : [];
  const customVerses = Array.isArray(body.customVerses) ? body.customVerses : [];
  const isAnswered = Boolean(body.isAnswered);
  const answeredNote = body.answeredNote ? String(body.answeredNote) : null;
  const answeredAt = isAnswered
    ? body.answeredAt || new Date().toISOString()
    : null;
  const clientUpdatedAt = body.updatedAt
    ? new Date(body.updatedAt)
    : new Date();

  const existing = await query(
    `SELECT * FROM shared_prayers WHERE sync_id = $1`,
    [syncId],
  );

  if (existing.rows.length) {
    const row = existing.rows[0];
    const canEdit =
      row.author_user_id === user.id ||
      (shareScope === 'church' && membership.role === 'owner');
    if (!canEdit && row.author_user_id !== user.id) {
      // Authors always edit their own; owner may edit church prayers for answered state via web.
      if (!(membership.role === 'owner' && row.share_scope === 'church')) {
        const err = new Error('You can only edit your own prayer.');
        err.status = 403;
        throw err;
      }
    }
    if (new Date(row.updated_at) > clientUpdatedAt) {
      return mapPrayer(row);
    }
    const { rows } = await query(
      `UPDATE shared_prayers SET
         name = $2, person = $3, request = $4,
         is_answered = $5, answered_at = $6, answered_note = $7,
         tags = $8::jsonb, verse_ids = $9::jsonb, custom_verses = $10::jsonb,
         share_scope = $11, group_id = $12,
         author_display_name = $13, updated_at = $14
       WHERE sync_id = $1
       RETURNING *`,
      [
        syncId,
        name,
        person,
        request,
        isAnswered,
        answeredAt,
        answeredNote,
        JSON.stringify(tags),
        JSON.stringify(verseIds),
        JSON.stringify(customVerses),
        shareScope,
        groupId,
        displayName || row.author_display_name,
        clientUpdatedAt.toISOString(),
      ],
    );
    await query('DELETE FROM prayer_tombstones WHERE sync_id = $1', [syncId]);
    return mapPrayer(rows[0]);
  }

  // Revive from tombstone only if client is newer — else refuse.
  const tomb = await query(
    `SELECT * FROM prayer_tombstones WHERE sync_id = $1`,
    [syncId],
  );
  if (tomb.rows.length && new Date(tomb.rows[0].deleted_at) >= clientUpdatedAt) {
    const err = new Error('This prayer was removed.');
    err.status = 410;
    throw err;
  }

  const { rows } = await query(
    `INSERT INTO shared_prayers (
       sync_id, author_user_id, author_display_name, church_id, group_id,
       share_scope, name, person, request, is_answered, answered_at,
       answered_note, tags, verse_ids, custom_verses, created_at, updated_at
     ) VALUES (
       $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13::jsonb,$14::jsonb,$15::jsonb,$16,$16
     ) RETURNING *`,
    [
      syncId,
      user.id,
      displayName,
      membership.church_id,
      groupId,
      shareScope,
      name,
      person,
      request,
      isAnswered,
      answeredAt,
      answeredNote,
      JSON.stringify(tags),
      JSON.stringify(verseIds),
      JSON.stringify(customVerses),
      clientUpdatedAt.toISOString(),
    ],
  );
  await query('DELETE FROM prayer_tombstones WHERE sync_id = $1', [syncId]);
  return mapPrayer(rows[0]);
}

export async function deleteSharedPrayer(user, syncId) {
  const membership = await getMembership(user.id);
  if (!membership) {
    const err = new Error('Join a group first.');
    err.status = 403;
    throw err;
  }

  const { rows } = await query(
    `SELECT * FROM shared_prayers WHERE sync_id = $1`,
    [syncId],
  );
  if (!rows.length) {
    await query(
      `INSERT INTO prayer_tombstones (sync_id, church_id, group_id, share_scope)
       VALUES ($1, $2, $3, 'church')
       ON CONFLICT (sync_id) DO UPDATE SET deleted_at = now()`,
      [syncId, membership.church_id, membership.group_id],
    );
    return { ok: true };
  }

  const row = rows[0];
  const allowed =
    row.author_user_id === user.id ||
    (row.share_scope === 'church' && membership.role === 'owner');
  if (!allowed) {
    const err = new Error('You cannot remove this prayer.');
    err.status = 403;
    throw err;
  }

  await query('DELETE FROM shared_prayers WHERE sync_id = $1', [syncId]);
  await query(
    `INSERT INTO prayer_tombstones (sync_id, church_id, group_id, share_scope)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (sync_id) DO UPDATE SET deleted_at = now()`,
    [syncId, row.church_id, row.group_id, row.share_scope],
  );
  return { ok: true };
}

export async function listNotes(user) {
  const membership = await getMembership(user.id);
  if (!membership) {
    const err = new Error('Join a group to see notes.');
    err.status = 403;
    throw err;
  }
  const { rows } = await query(
    `SELECT * FROM study_notes WHERE group_id = $1 ORDER BY updated_at DESC`,
    [membership.group_id],
  );
  return rows.map((r) => ({
    id: r.id,
    kind: r.kind,
    body: r.body,
    authorUserId: r.author_user_id,
    authorDisplayName: r.author_display_name,
    createdAt: r.created_at,
    updatedAt: r.updated_at,
  }));
}

export async function upsertNote(user, body) {
  const membership = await getMembership(user.id);
  if (!membership) {
    const err = new Error('Join a group first.');
    err.status = 403;
    throw err;
  }
  const kind = body.kind === 'current_study' ? 'current_study' : 'other';
  const noteBody = String(body.body || '').trim();
  if (!noteBody) {
    const err = new Error('Write a note first.');
    err.status = 400;
    throw err;
  }
  const displayName = user.display_name || '';

  if (body.id) {
    const existing = await query(`SELECT * FROM study_notes WHERE id = $1`, [
      body.id,
    ]);
    if (!existing.rows.length || existing.rows[0].author_user_id !== user.id) {
      const err = new Error('You can only edit your own note.');
      err.status = 403;
      throw err;
    }
    const { rows } = await query(
      `UPDATE study_notes SET body = $2, kind = $3,
         author_display_name = $4, updated_at = now()
       WHERE id = $1 RETURNING *`,
      [body.id, noteBody, kind, displayName],
    );
    return rows[0];
  }

  if (kind === 'current_study') {
    const existing = await query(
      `SELECT id FROM study_notes
       WHERE group_id = $1 AND author_user_id = $2 AND kind = 'current_study'`,
      [membership.group_id, user.id],
    );
    if (existing.rows.length) {
      const { rows } = await query(
        `UPDATE study_notes SET body = $2, author_display_name = $3, updated_at = now()
         WHERE id = $1 RETURNING *`,
        [existing.rows[0].id, noteBody, displayName],
      );
      return rows[0];
    }
  }

  const { rows } = await query(
    `INSERT INTO study_notes
       (group_id, author_user_id, author_display_name, kind, body)
     VALUES ($1, $2, $3, $4, $5) RETURNING *`,
    [membership.group_id, user.id, displayName, kind, noteBody],
  );
  return rows[0];
}

export async function deleteNote(user, noteId) {
  const { rows } = await query(`SELECT * FROM study_notes WHERE id = $1`, [
    noteId,
  ]);
  if (!rows.length || rows[0].author_user_id !== user.id) {
    const err = new Error('You can only remove your own note.');
    err.status = 403;
    throw err;
  }
  await query('DELETE FROM study_notes WHERE id = $1', [noteId]);
  return { ok: true };
}
