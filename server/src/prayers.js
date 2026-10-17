import { query } from './db.js';
import { getMemberships } from './auth.js';

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

function churchIds(memberships) {
  return [...new Set(memberships.map((m) => m.church_id))];
}

function groupIds(memberships) {
  return memberships.map((m) => m.group_id);
}

function isOwnerOfChurch(memberships, churchId) {
  return memberships.some(
    (m) => m.church_id === churchId && m.role === 'owner',
  );
}

function belongsToGroup(memberships, groupId) {
  return memberships.some((m) => m.group_id === groupId);
}

function belongsToChurch(memberships, churchId) {
  return memberships.some((m) => m.church_id === churchId);
}

export async function listSharedPrayers(user, { scope, groupId } = {}) {
  const memberships = await getMemberships(user.id);
  if (!memberships.length) {
    const err = new Error('Join a group to see shared prayers.');
    err.status = 403;
    throw err;
  }

  const churches = churchIds(memberships);
  const groups = groupIds(memberships);

  let sql = `SELECT * FROM shared_prayers WHERE church_id = ANY($1::uuid[])`;
  const params = [churches];

  if (groupId) {
    if (!belongsToGroup(memberships, groupId)) {
      const err = new Error('You are not in that group.');
      err.status = 403;
      throw err;
    }
    const m = memberships.find((x) => x.group_id === groupId);
    sql = `SELECT * FROM shared_prayers WHERE church_id = $1
           AND (share_scope = 'church' OR (share_scope = 'group' AND group_id = $2))`;
    params.length = 0;
    params.push(m.church_id, groupId);
  } else if (scope === 'church') {
    sql += ` AND share_scope = 'church'`;
  } else if (scope === 'group') {
    sql += ` AND share_scope = 'group' AND group_id = ANY($2::uuid[])`;
    params.push(groups);
  } else {
    sql += ` AND (share_scope = 'church' OR (share_scope = 'group' AND group_id = ANY($2::uuid[])))`;
    params.push(groups);
  }
  sql += ` ORDER BY updated_at DESC`;

  const { rows } = await query(sql, params);
  const tombs = await query(
    `SELECT sync_id, deleted_at, share_scope, church_id, group_id
     FROM prayer_tombstones
     WHERE church_id = ANY($1::uuid[])`,
    [churches],
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
    memberships,
  };
}

export async function upsertSharedPrayer(user, body) {
  const memberships = await getMemberships(user.id);
  if (!memberships.length) {
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

  let targetGroupId =
    body.groupId != null && String(body.groupId).trim()
      ? String(body.groupId).trim()
      : null;
  let targetChurchId =
    body.churchId != null && String(body.churchId).trim()
      ? String(body.churchId).trim()
      : null;

  if (shareScope === 'group') {
    if (!targetGroupId) {
      targetGroupId = memberships[0].group_id;
    }
    if (!belongsToGroup(memberships, targetGroupId)) {
      const err = new Error('You can only share with a group you belong to.');
      err.status = 403;
      throw err;
    }
    const m = memberships.find((x) => x.group_id === targetGroupId);
    targetChurchId = m.church_id;
  } else {
    if (targetGroupId && belongsToGroup(memberships, targetGroupId)) {
      const m = memberships.find((x) => x.group_id === targetGroupId);
      targetChurchId = m.church_id;
    } else if (targetChurchId) {
      if (!belongsToChurch(memberships, targetChurchId)) {
        const err = new Error('You can only share with a church you belong to.');
        err.status = 403;
        throw err;
      }
    } else {
      targetChurchId = memberships[0].church_id;
    }
    targetGroupId = null;
  }

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
    if (!belongsToChurch(memberships, row.church_id)) {
      const err = new Error('You cannot edit this prayer.');
      err.status = 403;
      throw err;
    }
    const canEdit =
      row.author_user_id === user.id ||
      (row.share_scope === 'church' &&
        isOwnerOfChurch(memberships, row.church_id));
    if (!canEdit) {
      const err = new Error('You can only edit your own prayer.');
      err.status = 403;
      throw err;
    }
    if (new Date(row.updated_at) > clientUpdatedAt) {
      return mapPrayer(row);
    }
    // Keep original church/group unless author is rewriting scope within their memberships.
    const nextScope = shareScope;
    const nextGroupId = shareScope === 'group' ? targetGroupId : null;
    const nextChurchId =
      shareScope === 'group' ? targetChurchId : row.church_id;
    if (!belongsToChurch(memberships, nextChurchId)) {
      const err = new Error('You cannot move this prayer outside your church.');
      err.status = 403;
      throw err;
    }
    const { rows } = await query(
      `UPDATE shared_prayers SET
         name = $2, person = $3, request = $4,
         is_answered = $5, answered_at = $6, answered_note = $7,
         tags = $8::jsonb, verse_ids = $9::jsonb, custom_verses = $10::jsonb,
         share_scope = $11, group_id = $12, church_id = $13,
         author_display_name = $14, updated_at = $15
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
        nextScope,
        nextGroupId,
        nextChurchId,
        displayName || row.author_display_name,
        clientUpdatedAt.toISOString(),
      ],
    );
    await query('DELETE FROM prayer_tombstones WHERE sync_id = $1', [syncId]);
    return mapPrayer(rows[0]);
  }

  const tomb = await query(
    `SELECT * FROM prayer_tombstones WHERE sync_id = $1`,
    [syncId],
  );
  if (tomb.rows.length) {
    const t = tomb.rows[0];
    if (!belongsToChurch(memberships, t.church_id)) {
      const err = new Error('This prayer was removed.');
      err.status = 410;
      throw err;
    }
    if (new Date(t.deleted_at) >= clientUpdatedAt) {
      const err = new Error('This prayer was removed.');
      err.status = 410;
      throw err;
    }
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
      targetChurchId,
      shareScope === 'group' ? targetGroupId : null,
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
  const memberships = await getMemberships(user.id);
  if (!memberships.length) {
    const err = new Error('Join a group first.');
    err.status = 403;
    throw err;
  }

  const { rows } = await query(
    `SELECT * FROM shared_prayers WHERE sync_id = $1`,
    [syncId],
  );
  if (!rows.length) {
    // Do not invent a tombstone for an unknown id outside the caller's churches.
    return { ok: true };
  }

  const row = rows[0];
  if (!belongsToChurch(memberships, row.church_id)) {
    const err = new Error('You cannot remove this prayer.');
    err.status = 403;
    throw err;
  }
  const allowed =
    row.author_user_id === user.id ||
    (row.share_scope === 'church' &&
      isOwnerOfChurch(memberships, row.church_id));
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

export async function listNotes(user, { groupId } = {}) {
  const memberships = await getMemberships(user.id);
  if (!memberships.length) {
    const err = new Error('Join a group to see notes.');
    err.status = 403;
    throw err;
  }

  let groups = groupIds(memberships);
  if (groupId) {
    if (!belongsToGroup(memberships, groupId)) {
      const err = new Error('You are not in that group.');
      err.status = 403;
      throw err;
    }
    groups = [groupId];
  }

  const { rows } = await query(
    `SELECT * FROM study_notes WHERE group_id = ANY($1::uuid[])
     ORDER BY updated_at DESC`,
    [groups],
  );
  return rows.map((r) => ({
    id: r.id,
    groupId: r.group_id,
    kind: r.kind,
    body: r.body,
    authorUserId: r.author_user_id,
    authorDisplayName: r.author_display_name,
    createdAt: r.created_at,
    updatedAt: r.updated_at,
  }));
}

export async function upsertNote(user, body) {
  const memberships = await getMemberships(user.id);
  if (!memberships.length) {
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

  let targetGroupId =
    body.groupId != null && String(body.groupId).trim()
      ? String(body.groupId).trim()
      : memberships[0].group_id;
  if (!belongsToGroup(memberships, targetGroupId)) {
    const err = new Error('You can only write notes in a group you belong to.');
    err.status = 403;
    throw err;
  }

  if (body.id) {
    const existing = await query(`SELECT * FROM study_notes WHERE id = $1`, [
      body.id,
    ]);
    if (!existing.rows.length || existing.rows[0].author_user_id !== user.id) {
      const err = new Error('You can only edit your own note.');
      err.status = 403;
      throw err;
    }
    if (!belongsToGroup(memberships, existing.rows[0].group_id)) {
      const err = new Error('You can only edit notes in a group you belong to.');
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
      [targetGroupId, user.id],
    );
    if (existing.rows.length) {
      const { rows } = await query(
        `UPDATE study_notes
         SET body = $2, author_display_name = $3,
             created_at = now(), updated_at = now()
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
    [targetGroupId, user.id, displayName, kind, noteBody],
  );
  return rows[0];
}

export async function deleteNote(user, noteId) {
  const memberships = await getMemberships(user.id);
  const { rows } = await query(`SELECT * FROM study_notes WHERE id = $1`, [
    noteId,
  ]);
  if (!rows.length || rows[0].author_user_id !== user.id) {
    const err = new Error('You can only remove your own note.');
    err.status = 403;
    throw err;
  }
  if (!belongsToGroup(memberships, rows[0].group_id)) {
    const err = new Error('You can only remove notes in a group you belong to.');
    err.status = 403;
    throw err;
  }
  await query('DELETE FROM study_notes WHERE id = $1', [noteId]);
  return { ok: true };
}
