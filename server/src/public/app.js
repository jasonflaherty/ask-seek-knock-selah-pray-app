const authEl = document.getElementById('auth');
const appEl = document.getElementById('app');
const authMsg = document.getElementById('auth-msg');
const addMsg = document.getElementById('add-msg');
const prayerList = document.getElementById('prayer-list');
const who = document.getElementById('who');
const membershipEl = document.getElementById('membership');

let filter = 'active';
let me = null;
let prayers = [];

function showMsg(el, text, isError) {
  el.hidden = !text;
  el.textContent = text || '';
  el.classList.toggle('error', Boolean(isError));
}

function uuid() {
  if (crypto.randomUUID) return crypto.randomUUID();
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

async function api(path, options = {}) {
  const res = await fetch(path, {
    credentials: 'include',
    headers: { 'Content-Type': 'application/json', ...(options.headers || {}) },
    ...options,
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error || 'Request failed');
  return data;
}

async function refreshMe() {
  try {
    me = await api('/api/me');
    authEl.classList.add('hidden');
    appEl.classList.remove('hidden');
    who.textContent = me.user.displayName
      ? `${me.user.displayName} (${me.user.email})`
      : me.user.email;
    if (!me.membership) {
      membershipEl.textContent =
        'You are not in a group yet. Create or join a group in the Selah app first.';
      prayers = [];
      renderPrayers();
      return;
    }
    membershipEl.textContent = `${me.membership.churchName} · ${me.membership.groupName}`;
    await loadPrayers();
  } catch {
    authEl.classList.remove('hidden');
    appEl.classList.add('hidden');
  }
}

async function loadPrayers() {
  const data = await api('/api/prayers?scope=church');
  prayers = data.prayers || [];
  renderPrayers();
}

function renderPrayers() {
  const visible = prayers.filter((p) => {
    if (filter === 'active') return !p.isAnswered;
    if (filter === 'answered') return p.isAnswered;
    return true;
  });
  prayerList.innerHTML = '';
  if (!visible.length) {
    const li = document.createElement('li');
    li.textContent = 'No church prayers yet.';
    prayerList.appendChild(li);
    return;
  }
  for (const p of visible) {
    const li = document.createElement('li');
    const title = document.createElement('strong');
    title.textContent = p.name;
    li.appendChild(title);
    const meta = document.createElement('p');
    meta.className = 'meta';
    const bits = [];
    if (p.person) bits.push(`For ${p.person}`);
    if (p.authorDisplayName) bits.push(`From ${p.authorDisplayName}`);
    bits.push(p.isAnswered ? 'Answered' : 'Active');
    meta.textContent = bits.join(' · ');
    li.appendChild(meta);
    const body = document.createElement('p');
    body.textContent = p.request;
    li.appendChild(body);
    if (p.isAnswered && p.answeredNote) {
      const note = document.createElement('p');
      note.className = 'meta';
      note.textContent = p.answeredNote;
      li.appendChild(note);
    }
    const actions = document.createElement('div');
    actions.className = 'actions';
    const canRemove =
      me &&
      (p.authorUserId === me.user.id || me.membership?.role === 'owner');
    if (!p.isAnswered) {
      const ans = document.createElement('button');
      ans.type = 'button';
      ans.className = 'ghost';
      ans.textContent = 'Mark answered';
      ans.addEventListener('click', () => markAnswered(p));
      actions.appendChild(ans);
    }
    if (canRemove) {
      const del = document.createElement('button');
      del.type = 'button';
      del.className = 'danger';
      del.textContent = 'Remove';
      del.addEventListener('click', () => removePrayer(p));
      actions.appendChild(del);
    }
    li.appendChild(actions);
    prayerList.appendChild(li);
  }
}

async function markAnswered(p) {
  try {
    await api(`/api/prayers/${encodeURIComponent(p.syncId)}`, {
      method: 'PUT',
      body: JSON.stringify({
        ...p,
        isAnswered: true,
        answeredAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      }),
    });
    await loadPrayers();
  } catch (e) {
    alert(e.message);
  }
}

async function removePrayer(p) {
  if (!confirm(`Remove “${p.name}”?`)) return;
  try {
    await api(`/api/prayers/${encodeURIComponent(p.syncId)}`, {
      method: 'DELETE',
    });
    await loadPrayers();
  } catch (e) {
    alert(e.message);
  }
}

document.getElementById('request-code').addEventListener('click', async () => {
  showMsg(authMsg, '');
  try {
    await api('/api/auth/request-code', {
      method: 'POST',
      body: JSON.stringify({ email: document.getElementById('email').value }),
    });
    document.getElementById('code-label').classList.remove('hidden');
    document.getElementById('verify-code').classList.remove('hidden');
    showMsg(authMsg, 'Check your email for a six-digit code.');
  } catch (e) {
    showMsg(authMsg, e.message, true);
  }
});

document.getElementById('verify-code').addEventListener('click', async () => {
  showMsg(authMsg, '');
  try {
    await api('/api/auth/verify-code', {
      method: 'POST',
      body: JSON.stringify({
        email: document.getElementById('email').value,
        code: document.getElementById('code').value,
      }),
    });
    await refreshMe();
  } catch (e) {
    showMsg(authMsg, e.message, true);
  }
});

document.getElementById('sign-out').addEventListener('click', async () => {
  await api('/api/auth/sign-out', { method: 'POST' });
  location.reload();
});

document.getElementById('refresh').addEventListener('click', () => loadPrayers());

document.getElementById('add-prayer').addEventListener('click', async () => {
  showMsg(addMsg, '');
  if (!me?.membership) {
    showMsg(addMsg, 'Join a group in the app first.', true);
    return;
  }
  const name = document.getElementById('new-name').value.trim();
  const person = document.getElementById('new-person').value.trim();
  const request = document.getElementById('new-request').value.trim();
  if (!name || !request) {
    showMsg(addMsg, 'Title and request are required.', true);
    return;
  }
  const syncId = uuid();
  const now = new Date().toISOString();
  try {
    await api(`/api/prayers/${encodeURIComponent(syncId)}`, {
      method: 'PUT',
      body: JSON.stringify({
        syncId,
        shareScope: 'church',
        name,
        person,
        request,
        isAnswered: false,
        tags: [],
        verseIds: [],
        customVerses: [],
        updatedAt: now,
        createdAt: now,
      }),
    });
    document.getElementById('new-name').value = '';
    document.getElementById('new-person').value = '';
    document.getElementById('new-request').value = '';
    showMsg(addMsg, 'Church prayer added.');
    await loadPrayers();
  } catch (e) {
    showMsg(addMsg, e.message, true);
  }
});

document.getElementById('filters').addEventListener('click', (ev) => {
  const btn = ev.target.closest('[data-filter]');
  if (!btn) return;
  filter = btn.dataset.filter;
  document.querySelectorAll('#filters .chip').forEach((c) => {
    c.classList.toggle('active', c === btn);
  });
  renderPrayers();
});

refreshMe();
