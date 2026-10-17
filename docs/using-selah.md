# Using Selah

Selah is a prayer journal on your phone. You can join one group so you can share some prayers and reading notes.

## What stays private

- **Just me** prayers stay on this phone. They are never uploaded.
- Your email address stays on your account. Other people see the short name you choose.

## What the group and church can see

- **Group** prayers are for the people in your reading group.
- **Church** prayers are for everyone in that church. They appear in the app and on the church web page (the same site as your API base URL).
- **Reading notes** (what you are reading and other notes) are visible to your group.

## Sign in

1. Open **Settings**.
2. Enter your email and tap **Send sign-in code**.
3. Open the email, copy the six-digit code, and tap **Sign in**.
4. Set a short **display name** so the group knows who wrote a prayer or note.

You do not need a password.

## Create or ask to join a group

Each person belongs to **one** group.

**To create a group**

1. Sign in and set a display name.
2. Enter the church name and the group name.
3. Tap **Create group**.
4. Share the **invite code** (only the owner sees it), or invite by email (below).

The owner can change the church name and the group name later in Settings. Tap **Save names**. Everyone in the group sees the new names.

**Invite by email (pre-approved)**

1. Owner opens **People and requests** in Settings.
2. Enter their email and tap **Send invitation**.
3. They open the link in the email (web page on your Selah site), or open the Selah app.
4. They sign in with **that same email** (one-time code).
5. They join the group automatically — no extra Allow step.

The email link looks like `https://your-selah-host.example/invite.html?code=ABCD1234`. The code is also in the message if they prefer the app.

**To ask to join with a code (not pre-approved)**

1. Sign in and set a display name.
2. Enter the invite code from the group owner.
3. Tap **Ask to join**.
4. Wait until the owner taps **Allow**. Until then you are not a member and sync does not start.

In **People and requests** the owner also sees waiting code requests (**Allow** / **Do not allow**) and the member list.

If you already had prayers marked Church on this phone, Selah will ask whether to share them with this church. Choose carefully. Private (Just me) prayers are never part of that question.

To change groups, leave (or delete, if you are the owner) your current group first, then create or ask to join another.

## Add a prayer

1. Tap **Add petition**.
2. Write the title and the request.
3. Choose **Just me**, **Group**, or **Church**. Group and Church are available after you join a group.
4. You may attach Scripture.
5. Save.

## Morning reminder and timers

On **10/10** you can turn on a morning reminder and pick the time (Pacific Time). The first time you turn it on (or change the time), the phone may ask to allow notifications — allow them, or the reminder will not appear. The reminder says: “Read for 10 minutes, then pray for 10 minutes.” Tapping the reminder opens **10/10**.

Open **Read and pray** from the bottom bar (**10/10**):

1. Tap **Start reading (10 min)**.
2. When the reading time ends, a short ding plays and the pray timer starts. You may skip to prayer early (no ding).
3. When the pray time ends, another ding plays.
4. You may pause or stop at any time.

If you are in a group, the same screen lets you write **what you are reading** and other notes for the group. Each person posts their own; there is no single assigned book.

## Church page on the web

1. Open your Selah site (the HTTPS address of your API / church page).
2. Sign in with the same email and code.
3. Add, mark answered, or remove church prayers.

The person who wrote a church prayer, or the group owner, can remove it. Changes show up in the app after sync. Allowing people into a group is done only in the phone app.

## New phone

After you sign in on a new phone, group and church prayers return. Just me prayers stay on the old phone unless you restore a backup from that phone (Settings → Backup).

## The prayer timer for names

The separate **Prayer timer** (timer icon) still walks through petition names and plays a short ding when the timer finishes. It is not the same as Read and pray.
