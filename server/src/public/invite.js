const params = new URLSearchParams(window.location.search);
const inviteCode = (params.get('code') || '').trim().toUpperCase();

const previewMsg = document.getElementById('preview-msg');
const lede = document.getElementById('lede');
const authEl = document.getElementById('auth');
const doneEl = document.getElementById('done');
const authMsg = document.getElementById('auth-msg');
const emailInput = document.getElementById('email');
const codeLabel = document.getElementById('code-label');
const codeInput = document.getElementById('code');
const verifyBtn = document.getElementById('verify-code');

function showMsg(el, text, isError) {
  el.hidden = !text;
  el.textContent = text || '';
  el.classList.toggle('error', Boolean(isError));
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

function membershipsOf(data) {
  if (Array.isArray(data.memberships) && data.memberships.length) {
    return data.memberships;
  }
  if (data.membership) return [data.membership];
  return [];
}

async function loadPreview() {
  if (!inviteCode) {
    previewMsg.textContent =
      'This link is missing an invite code. Ask the group owner to send a new invitation.';
    previewMsg.classList.add('error');
    authEl.classList.add('hidden');
    return;
  }
  try {
    const preview = await api(
      `/api/invite-preview?code=${encodeURIComponent(inviteCode)}`,
    );
    previewMsg.classList.remove('error');
    previewMsg.textContent = `${preview.churchName} · ${preview.groupName}`;
    lede.textContent =
      'Sign in with the email that received this invitation. After you sign in, you join the group automatically.';
  } catch (e) {
    previewMsg.textContent = e.message || 'Invitation not found.';
    previewMsg.classList.add('error');
    authEl.classList.add('hidden');
  }
}

function showJoined(me) {
  const list = membershipsOf(me);
  authEl.classList.add('hidden');
  doneEl.classList.remove('hidden');
  const m = list[0];
  document.getElementById('done-msg').textContent = m
    ? `Welcome to ${m.groupName} (${m.churchName}). You can use the Selah app or the church prayer page.`
    : 'Signed in. If you were invited to this email, open the app and sync — or ask the owner to send the invite again.';
}

document.getElementById('request-code').addEventListener('click', async () => {
  showMsg(authMsg, '');
  try {
    await api('/api/auth/request-code', {
      method: 'POST',
      body: JSON.stringify({ email: emailInput.value }),
    });
    codeLabel.classList.remove('hidden');
    verifyBtn.classList.remove('hidden');
    showMsg(authMsg, 'Check your email for the sign-in code.');
  } catch (e) {
    showMsg(authMsg, e.message, true);
  }
});

verifyBtn.addEventListener('click', async () => {
  showMsg(authMsg, '');
  try {
    const me = await api('/api/auth/verify-code', {
      method: 'POST',
      body: JSON.stringify({
        email: emailInput.value,
        code: codeInput.value,
      }),
    });
    // Pre-approve applies on verify. If still not in a group, try the code path.
    let list = membershipsOf(me);
    if (!list.length && inviteCode) {
      const joined = await api('/api/groups/join', {
        method: 'POST',
        body: JSON.stringify({ inviteCode }),
      });
      list = membershipsOf(joined);
      showJoined(joined);
      return;
    }
    showJoined(me);
  } catch (e) {
    showMsg(authMsg, e.message, true);
  }
});

(async () => {
  await loadPreview();
  try {
    const me = await api('/api/me');
    if (membershipsOf(me).length) {
      showJoined(me);
      return;
    }
    if (inviteCode) {
      try {
        const joined = await api('/api/groups/join', {
          method: 'POST',
          body: JSON.stringify({ inviteCode }),
        });
        if (membershipsOf(joined).length) {
          showJoined(joined);
        }
      } catch {
        // Stay on sign-in / display-name may be required.
      }
    }
  } catch {
    // Not signed in.
  }
})();
