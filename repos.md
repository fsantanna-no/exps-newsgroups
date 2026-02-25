# Two-Repo Sync Experiment

## Goal

Two local git repos, each representing a different "peer." Each has MH newsgroup folders. Claws Mail sees both as separate mailbox trees. A sync script merges them via git, and Claws picks up changes live.

No Freechains, no GPG signing — just plain MH files in git, synced between peers.

---

## 1. Newsgroup Layout

Five newsgroups per side. Three shared, two unique to each peer.

### Hierarchy design

- `comp.lang.lua` — standalone (shared)
- `sci.crypt` / `sci.crypt.random` — two-level hierarchy (shared root, unique leaf)
- `alt.test` / `alt.test.sandbox` — two-level hierarchy (unique)

### Per-repo allocation

| Newsgroup           | Repo A (alice) | Repo B (bob) |
|---------------------|:--------------:|:------------:|
| `comp.lang.lua`     | ✓              | ✓            |
| `sci.crypt`         | ✓              | ✓            |
| `sci.crypt.random`  | ✓              |              |
| `alt.test`          | ✓              |              |
| `alt.test.sandbox`  |                | ✓            |
| `rec.music.synth`   |                | ✓            |

- **3 in common**: `comp.lang.lua`, `sci.crypt`, `sci.crypt.random` (alice) / `alt.test.sandbox` (bob) — wait, let me redo this cleanly.

Actually, re-reading the requirement: "5 newsgroups in each side, 3 in common. Use 2 in a hier, 1 alone, and 2 in another hier."

So each side has exactly 5 newsgroups. 3 of those are the same on both sides. Each side has 2 unique ones. Total distinct newsgroups = 3 + 2 + 2 = 7.

The structure "2 in a hier, 1 alone, 2 in another hier" describes how the 5 per side are organized: two hierarchies of 2, plus 1 standalone.

### Revised layout

**Shared newsgroups (3):**

| Newsgroup         | Type      |
|-------------------|-----------|
| `comp.lang.lua`   | standalone |
| `sci.crypt`       | hier root  |
| `sci.crypt.random`| hier child |

**Alice-only (2):**

| Newsgroup        | Type       |
|------------------|------------|
| `alt.test`       | hier root  |
| `alt.test.flood` | hier child |

**Bob-only (2):**

| Newsgroup          | Type       |
|--------------------|------------|
| `rec.music`        | hier root  |
| `rec.music.synth`  | hier child |

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

## 2. Directory Structure

Use MH convention: dots become directory separators. Each newsgroup is a directory. Messages are numbered files (plain sequential MH for now — no timestamp+hash scheme yet).

```
repo-alice/
  comp.lang.lua/
    1
    2
    3
  sci.crypt/
    1
    2
  sci.crypt.random/
    1
  alt.test/
    1
    2
  alt.test.flood/
    1

repo-bob/
  comp.lang.lua/
    (empty — will receive from alice via sync)
  sci.crypt/
    (empty)
  sci.crypt.random/
    (empty)
  rec.music/
    1
    2
  rec.music.synth/
    1
```

Bob starts **empty in all shared groups** — his only messages are in his unique groups. This tests the "pull everything from scratch" sync path.

---

## 3. Sample Messages

Each message is a valid RFC 2822 file with Usenet-style headers. No messages repeated across repos.

### Alice's messages

**comp.lang.lua/1**
```
From: alice@example.com
Newsgroups: comp.lang.lua
Subject: Lua 5.5 coroutine changes
Message-ID: <lua-coro-01@alice>
Date: Mon, 24 Feb 2026 10:00:00 -0300

Has anyone tested the new coroutine.close() behavior in 5.5?
It seems to finalize to-be-closed variables differently.
```

**comp.lang.lua/2**
```
From: alice@example.com
Newsgroups: comp.lang.lua
Subject: LPeg vs re module performance
Message-ID: <lua-lpeg-01@alice>
Date: Mon, 24 Feb 2026 11:00:00 -0300

I benchmarked LPeg against the re module for CSV parsing.
LPeg is ~3x faster for complex grammars. Results attached.
```

**comp.lang.lua/3**
```
From: alice@example.com
Newsgroups: comp.lang.lua
Subject: Embedding Lua in C - best practices 2026
Message-ID: <lua-embed-01@alice>
Date: Mon, 24 Feb 2026 12:00:00 -0300

What's the current best practice for embedding Lua in a C
application? Is lua_newstate+custom allocator still the way?
```

**sci.crypt/1**
```
From: alice@example.com
Newsgroups: sci.crypt
Subject: Post-quantum key exchange in practice
Message-ID: <crypt-pq-01@alice>
Date: Mon, 24 Feb 2026 13:00:00 -0300

ML-KEM is now in TLS 1.3 drafts. Anyone deploying hybrid
key exchange (X25519 + ML-KEM-768) in production?
```

**sci.crypt/2**
```
From: alice@example.com
Newsgroups: sci.crypt
Subject: Re: Hash function for content addressing
Message-ID: <crypt-hash-01@alice>
Date: Mon, 24 Feb 2026 14:00:00 -0300

For content-addressed storage, BLAKE3 is hard to beat.
256-bit output, tree-hashing built in, faster than SHA-256.
```

**sci.crypt.random/1**
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

**alt.test/1**
```
From: alice@example.com
Newsgroups: alt.test
Subject: Testing MH format with git
Message-ID: <test-mh-01@alice>
Date: Mon, 24 Feb 2026 16:00:00 -0300

This is a test message to verify MH file handling in git.
If you can read this, the format works.
```

**alt.test/2**
```
From: alice@example.com
Newsgroups: alt.test
Subject: Second test message
Message-ID: <test-mh-02@alice>
Date: Mon, 24 Feb 2026 16:30:00 -0300

Another test. Checking that sequential numbering and
git add/commit work with multiple messages.
```

**alt.test.flood/1**
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

**rec.music/1**
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

**rec.music/2**
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

**rec.music.synth/1**
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

## 4. Repo Initialization

### Step 4a: Create the bare "hub" repo

Both peers sync through a bare repo that acts as the shared remote. This avoids pushing into a checked-out branch.

```bash
mkdir -p ~/exps-newsgroups-lab
git init --bare ~/exps-newsgroups-lab/hub.git
```

### Step 4b: Create repo-alice

```bash
cd ~/exps-newsgroups-lab
git clone hub.git repo-alice
cd repo-alice

# Create newsgroup directories and populate messages
mkdir -p comp.lang.lua sci.crypt sci.crypt.random alt.test alt.test.flood

# Write all alice's messages (see section 3 above) into the directories
# ... (each message written as the numbered file)

git add .
git commit -m "alice: initial messages"
git push -u origin main
```

### Step 4c: Create repo-bob

```bash
cd ~/exps-newsgroups-lab
git clone hub.git repo-bob
cd repo-bob

# Pull alice's content first (comes from hub)
# Then create bob-only directories
mkdir -p rec.music rec.music.synth

# Write bob's messages
# ... (each message written as the numbered file)

# Also create empty shared dirs if not already present from clone
mkdir -p comp.lang.lua sci.crypt sci.crypt.random

git add .
git commit -m "bob: initial messages"
git push -u origin main
```

---

## 5. Sync Script

A simple `sync.sh` that does bidirectional git sync between a local repo and the hub.

```bash
#!/bin/bash
# sync.sh — run inside a repo (repo-alice or repo-bob)
# Pulls from hub, merges, pushes back.

set -e

echo "=== Pulling from hub ==="
git pull --no-edit origin main

echo "=== Pushing to hub ==="
git push origin main

echo "=== Sync complete ==="
```

Because messages have **unique filenames** (different numbers, different groups), git merges are always clean — no two peers create the same file path.

For continuous "live" sync, wrap in a watch loop:

```bash
#!/bin/bash
# watch-sync.sh — poll-based sync every N seconds
INTERVAL=${1:-5}
while true; do
    bash sync.sh 2>&1 | grep -v "Already up to date"
    sleep "$INTERVAL"
done
```

---

## 6. Claws Mail Configuration

Claws Mail reads MH folders directly from the filesystem. Each repo appears as a separate "mailbox" (account folder tree).

### Step 6a: Add repo-alice as a mailbox

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

### Step 6b: Add repo-bob as a mailbox

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

### Step 6c: Verify display

- Click on `repo-alice/comp.lang.lua` — should show 3 messages
- Click on `repo-bob/comp.lang.lua` — should show 0 messages
- Both mailbox trees are visible simultaneously in the folder pane

---

## 7. Live Sync Demo

### Step 7a: Start the sync watcher on Bob's side

```bash
cd ~/exps-newsgroups-lab/repo-bob
bash watch-sync.sh 5
```

This pulls from hub every 5 seconds.

### Step 7b: Trigger a sync

In another terminal:

```bash
cd ~/exps-newsgroups-lab/repo-alice
git pull origin main   # get any hub updates
git push origin main   # push alice's messages to hub
```

Within 5 seconds, `watch-sync.sh` in repo-bob pulls the changes.

### Step 7c: Refresh Claws Mail

Claws does not auto-detect filesystem changes. After sync:

- Right-click `repo-bob` in the folder pane → **Check for new messages**
- Or press the global **Get Mail** button (it checks all accounts/mailboxes)
- Or set up a **folder processing rule** to auto-check at an interval

After refresh, `repo-bob/comp.lang.lua` now shows 3 messages (alice's), while `repo-bob/rec.music` still has 2 (bob's originals).

### Step 7d: Verify bidirectional sync

```bash
# On bob's side, create a new message
cat > ~/exps-newsgroups-lab/repo-bob/comp.lang.lua/4 << 'EOF'
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
git push origin main
```

Then on alice's side:

```bash
cd ~/exps-newsgroups-lab/repo-alice
git pull origin main
```

Refresh Claws on alice's mailbox — `comp.lang.lua` now shows 4 messages.

---

## 8. What This Proves

After running this experiment:

- **MH + git works**: plain numbered files in directories, version-controlled, mergeable
- **Claws reads it natively**: no import, no conversion, just point at the directory
- **Bidirectional sync is trivial**: git pull/push with no merge conflicts (unique filenames)
- **Live updates**: Claws picks up new files on refresh
- **Hierarchy preserved**: `sci.crypt/` and `sci.crypt.random/` appear as sibling folders, matching the newsgroup hierarchy convention

### Limitations of this simple setup

- **Sequential MH numbers are local** — the `4` that bob creates in `comp.lang.lua` could collide if alice also creates a `4`. The timestamp+hash scheme from `all.md` solves this, but is not used here.
- **No deduplication** — if the same message appears in two repos with different numbers, sync won't detect it as a duplicate.
- **Manual git operations** — no daemon, no hooks, just scripts. A real setup would use git hooks or inotify.
- **No signing, no content addressing** — this is intentionally the simplest possible layer. Freechains properties come later.
