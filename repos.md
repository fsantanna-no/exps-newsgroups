# Two-Repo Sync Experiment

## Goal

Two local git repos, each representing a different "peer." Each has MH newsgroup folders. Claws Mail sees both as separate mailbox trees. A sync script merges them via `git pull file://`, and Claws picks up changes live.

No Freechains, no GPG signing — just plain MH files in git, synced between peers.

---

## 1. Newsgroup Layout

Five newsgroups per side. Three shared, two unique to each peer.

### Hierarchy design

- `comp.lang.lua` — standalone (shared)
- `sci.crypt` / `sci.crypt.random` — two-level hierarchy (shared)
- `alt.test` / `alt.test.flood` — two-level hierarchy (alice-only)
- `rec.music` / `rec.music.synth` — two-level hierarchy (bob-only)

### Per-repo allocation

| Newsgroup           | Repo A (alice) | Repo B (bob) |
|---------------------|:--------------:|:------------:|
| `comp.lang.lua`     | ✓              | ✓            |
| `sci.crypt`         | ✓              | ✓            |
| `sci.crypt.random`  | ✓              | ✓            |
| `alt.test`          | ✓              |              |
| `alt.test.flood`    | ✓              |              |
| `rec.music`         |                | ✓            |
| `rec.music.synth`   |                | ✓            |

### Alice's 5 newsgroups

```
comp.lang.lua        ← standalone (shared)
sci.crypt            ← hier 1 (shared)
sci.crypt.random     ← hier 1 (shared)
alt.test             ← hier 2 (alice-only)
alt.test.flood       ← hier 2 (alice-only)
```

### Bob's 5 newsgroups

```
comp.lang.lua        ← standalone (shared)
sci.crypt            ← hier 1 (shared)
sci.crypt.random     ← hier 1 (shared)
rec.music            ← hier 2 (bob-only)
rec.music.synth      ← hier 2 (bob-only)
```

---

## 2. Filename Convention

To avoid collisions without coordination, each peer owns a trailing digit:

- **Alice**: all filenames end in `1` → `11, 21, 31, 41, ...`
- **Bob**: all filenames end in `2` → `12, 22, 32, 42, ...`

The last digit is the **peer ID**, the prefix is a local counter. Two peers can never produce the same filename. Scales to 10 peers (digits 0–9).

---

## 3. Directory Structure

Each newsgroup is a directory. Messages are numbered files using the trailing-digit scheme.

```
repo-alice/
  comp.lang.lua/
    11
    21
    31
  sci.crypt/
    11
    21
  sci.crypt.random/
    11
  alt.test/
    11
    21
  alt.test.flood/
    11

repo-bob/
  comp.lang.lua/
    (empty — will receive from alice via sync)
  sci.crypt/
    (empty)
  sci.crypt.random/
    (empty)
  rec.music/
    12
    22
  rec.music.synth/
    12
```

Bob starts **empty in all shared groups** — his only messages are in his unique groups. This tests the "pull everything from scratch" sync path.

---

## 4. Sample Messages

Each message is a valid RFC 2822 file with Usenet-style headers. No messages repeated across repos.

### Alice's messages

**comp.lang.lua/11**
```
From: alice@example.com
Newsgroups: comp.lang.lua
Subject: Lua 5.5 coroutine changes
Message-ID: <lua-coro-01@alice>
Date: Mon, 24 Feb 2026 10:00:00 -0300

Has anyone tested the new coroutine.close() behavior in 5.5?
It seems to finalize to-be-closed variables differently.
```

**comp.lang.lua/21**
```
From: alice@example.com
Newsgroups: comp.lang.lua
Subject: LPeg vs re module performance
Message-ID: <lua-lpeg-01@alice>
Date: Mon, 24 Feb 2026 11:00:00 -0300

I benchmarked LPeg against the re module for CSV parsing.
LPeg is ~3x faster for complex grammars. Results attached.
```

**comp.lang.lua/31**
```
From: alice@example.com
Newsgroups: comp.lang.lua
Subject: Embedding Lua in C - best practices 2026
Message-ID: <lua-embed-01@alice>
Date: Mon, 24 Feb 2026 12:00:00 -0300

What's the current best practice for embedding Lua in a C
application? Is lua_newstate+custom allocator still the way?
```

**sci.crypt/11**
```
From: alice@example.com
Newsgroups: sci.crypt
Subject: Post-quantum key exchange in practice
Message-ID: <crypt-pq-01@alice>
Date: Mon, 24 Feb 2026 13:00:00 -0300

ML-KEM is now in TLS 1.3 drafts. Anyone deploying hybrid
key exchange (X25519 + ML-KEM-768) in production?
```

**sci.crypt/21**
```
From: alice@example.com
Newsgroups: sci.crypt
Subject: Re: Hash function for content addressing
Message-ID: <crypt-hash-01@alice>
Date: Mon, 24 Feb 2026 14:00:00 -0300

For content-addressed storage, BLAKE3 is hard to beat.
256-bit output, tree-hashing built in, faster than SHA-256.
```

**sci.crypt.random/11**
```
From: alice@example.com
Newsgroups: sci.crypt.random
Subject: CSPRNG seeding on embedded Linux
Message-ID: <random-seed-01@alice>
Date: Mon, 24 Feb 2026 15:00:00 -0300

On embedded systems with no RTC, getrandom(2) blocks until
the entropy pool is initialized. What do people use for
early-boot randomness?
```

**alt.test/11**
```
From: alice@example.com
Newsgroups: alt.test
Subject: Testing MH format with git
Message-ID: <test-mh-01@alice>
Date: Mon, 24 Feb 2026 16:00:00 -0300

This is a test message to verify MH file handling in git.
If you can read this, the format works.
```

**alt.test/21**
```
From: alice@example.com
Newsgroups: alt.test
Subject: Second test message
Message-ID: <test-mh-02@alice>
Date: Mon, 24 Feb 2026 16:30:00 -0300

Another test. Checking that sequential numbering and
git add/commit work with multiple messages.
```

**alt.test.flood/11**
```
From: alice@example.com
Newsgroups: alt.test.flood
Subject: Flood test #1
Message-ID: <flood-01@alice>
Date: Mon, 24 Feb 2026 17:00:00 -0300

First message in the flood test group.
Used for volume/stress testing.
```

### Bob's messages

**rec.music/12**
```
From: bob@example.com
Newsgroups: rec.music
Subject: Analog vs digital synthesis in 2026
Message-ID: <music-synth-01@bob>
Date: Tue, 25 Feb 2026 09:00:00 -0300

With modern DACs and oversampling, can anyone actually
hear the difference between analog and digital oscillators
in a blind test?
```

**rec.music/22**
```
From: bob@example.com
Newsgroups: rec.music
Subject: Open-source firmware for MIDI controllers
Message-ID: <music-midi-01@bob>
Date: Tue, 25 Feb 2026 10:00:00 -0300

I've been hacking on open-source firmware for cheap MIDI
controllers. The latency improvements over stock firmware
are significant — sub-1ms over USB.
```

**rec.music.synth/12**
```
From: bob@example.com
Newsgroups: rec.music.synth
Subject: Modular synth patching as a graph problem
Message-ID: <synth-graph-01@bob>
Date: Tue, 25 Feb 2026 11:00:00 -0300

Every modular synth patch is a directed graph. Has anyone
applied graph theory to find optimal signal routing?
```

---

## 5. Repo Initialization

No bare hub repo. Both repos are regular git repos that pull from each other using `file://` paths. No daemon needed.

### Step 5a: Create repo-alice

```bash
mkdir -p ~/exps-newsgroups-lab/repo-alice
cd ~/exps-newsgroups-lab/repo-alice
git init

# Create newsgroup directories and populate messages
mkdir -p comp.lang.lua sci.crypt sci.crypt.random alt.test alt.test.flood

# Write all alice's messages (see section 4) into the directories
# ... (each message written as the numbered file)

git add .
git commit -m "alice: initial messages"
```

### Step 5b: Create repo-bob

```bash
mkdir -p ~/exps-newsgroups-lab/repo-bob
cd ~/exps-newsgroups-lab/repo-bob
git init

# Create bob-only directories with messages
mkdir -p rec.music rec.music.synth

# Write bob's messages (see section 4) into the directories
# ... (each message written as the numbered file)

# Create empty shared directories (so Claws sees the folders)
mkdir -p comp.lang.lua sci.crypt sci.crypt.random

git add .
git commit -m "bob: initial messages"
```

### Step 5c: Add cross-remotes

```bash
# In repo-alice, add bob as a remote
cd ~/exps-newsgroups-lab/repo-alice
git remote add bob file://$(realpath ../repo-bob)

# In repo-bob, add alice as a remote
cd ~/exps-newsgroups-lab/repo-bob
git remote add alice file://$(realpath ../repo-alice)
```

Now `git pull alice main` (from bob) or `git pull bob main` (from alice) syncs directly, no server.

---

## 6. Sync Script

A simple `sync.sh` that runs inside one repo and pulls from the other peer.

```bash
#!/bin/bash
# sync.sh <peer-name>
# Example: cd repo-bob && bash sync.sh alice

set -e
PEER=${1:?Usage: sync.sh <peer-name>}

echo "=== Pulling from $PEER ==="
git pull --no-edit "$PEER" main

echo "=== Sync complete ==="
```

Because messages have **unique filenames** (trailing-digit scheme), git merges are always clean — no two peers create the same file path.

For continuous "live" sync, wrap in a watch loop:

```bash
#!/bin/bash
# watch-sync.sh <peer-name> [interval]
# Example: cd repo-bob && bash watch-sync.sh alice 5

PEER=${1:?Usage: watch-sync.sh <peer-name> [interval]}
INTERVAL=${2:-5}
while true; do
    bash sync.sh "$PEER" 2>&1 | grep -v "Already up to date"
    sleep "$INTERVAL"
done
```

---

## 7. Claws Mail Configuration

Claws Mail reads MH folders directly from the filesystem. Each repo appears as a separate "mailbox" (account folder tree).

### Step 7a: Add repo-alice as a mailbox

1. Open Claws Mail
2. Go to **File → Add mailbox → MH...**
3. In the dialog, enter the path: `~/exps-newsgroups-lab/repo-alice`
4. Click OK
5. The folder tree appears in the left pane with:
   ```
   repo-alice
   ├── alt.test          (2 messages)
   ├── alt.test.flood    (1 message)
   ├── comp.lang.lua     (3 messages)
   ├── sci.crypt         (2 messages)
   └── sci.crypt.random  (1 message)
   ```

### Step 7b: Add repo-bob as a mailbox

1. Go to **File → Add mailbox → MH...**
2. Enter the path: `~/exps-newsgroups-lab/repo-bob`
3. Click OK
4. The folder tree appears:
   ```
   repo-bob
   ├── comp.lang.lua     (0 messages — empty, pre-sync)
   ├── rec.music         (2 messages)
   ├── rec.music.synth   (1 message)
   ├── sci.crypt         (0 messages — empty, pre-sync)
   └── sci.crypt.random  (0 messages — empty, pre-sync)
   ```

### Step 7c: Verify display

- Click on `repo-alice/comp.lang.lua` — should show 3 messages
- Click on `repo-bob/comp.lang.lua` — should show 0 messages
- Both mailbox trees are visible simultaneously in the folder pane

---

## 8. Live Sync Demo

### Step 8a: Start the sync watcher on Bob's side

```bash
cd ~/exps-newsgroups-lab/repo-bob
bash watch-sync.sh alice 5
```

This pulls from alice every 5 seconds via `file://`.

### Step 8b: Trigger a sync

Alice's repo already has messages committed. The watcher in repo-bob pulls them automatically on the next cycle.

Within 5 seconds, `watch-sync.sh` in repo-bob pulls alice's messages into the shared groups.

### Step 8c: Refresh Claws Mail

Claws does not auto-detect filesystem changes. After sync:

- Right-click `repo-bob` in the folder pane → **Check for new messages**
- Or press the global **Get Mail** button (it checks all accounts/mailboxes)
- Or set up a **folder processing rule** to auto-check at an interval

After refresh, `repo-bob/comp.lang.lua` now shows 3 messages (alice's), while `repo-bob/rec.music` still has 2 (bob's originals).

### Step 8d: Verify bidirectional sync

```bash
# On bob's side, create a new message (note: filename ends in 2)
cat > ~/exps-newsgroups-lab/repo-bob/comp.lang.lua/12 << 'EOF'
From: bob@example.com
Newsgroups: comp.lang.lua
Subject: Re: Lua 5.5 coroutine changes
Message-ID: <lua-coro-reply-01@bob>
Date: Tue, 25 Feb 2026 12:00:00 -0300
References: <lua-coro-01@alice>

Yes, I tested it. The finalization order changed in 5.5.
to-be-closed variables now close in reverse declaration order
within the same scope level.
EOF

cd ~/exps-newsgroups-lab/repo-bob
git add .
git commit -m "bob: reply to lua coroutine thread"
```

Then on alice's side, pull from bob:

```bash
cd ~/exps-newsgroups-lab/repo-alice
git pull bob main
```

Refresh Claws on alice's mailbox — `comp.lang.lua` now shows 4 messages (11, 21, 31 from alice + 12 from bob).

---

## 9. What This Proves

After running this experiment:

- **MH + git works**: plain numbered files in directories, version-controlled, mergeable
- **Claws reads it natively**: no import, no conversion, just point at the directory
- **file:// sync is trivial**: `git pull` between local repos, no server or daemon
- **Trailing-digit scheme prevents collisions**: alice's `*1` files never clash with bob's `*2` files
- **Bidirectional sync**: both peers can create messages and pull from each other
- **Live updates**: Claws picks up new files on refresh
- **Hierarchy preserved**: `sci.crypt/` and `sci.crypt.random/` appear as sibling folders, matching the newsgroup hierarchy convention

### Limitations of this simple setup

- **Trailing-digit numbering is peer-count-limited** — works for up to 10 peers. The timestamp+hash scheme from `all.md` removes this limit.
- **No deduplication** — not needed here (unique filenames by construction), but a real system needs it.
- **Manual git operations** — no daemon, no hooks, just scripts. A real setup would use git hooks or inotify.
- **No signing, no content addressing** — this is intentionally the simplest possible layer. Freechains properties come later.
- **Empty directories require a placeholder** — git doesn't track empty directories. Either add a `.gitkeep` or ensure Claws creates `.mh_sequences` on first access.
