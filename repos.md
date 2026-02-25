# Two-Repo Sync Experiment

## Goal

Two local git repos, each representing a different "peer" (machine/node). Each has MH newsgroup folders. Claws Mail sees both as separate mailbox trees. A sync script merges them via `git pull file://`, and Claws picks up changes live.

Repos are **not** identities. Five different people post across both repos. A repo is just where a message happens to originate — like two different NNTP servers that carry overlapping groups.

No Freechains, no GPG signing — just plain MH files in git, synced between peers.

---

## 1. Identities

Five people, each posting from one or both repos, across different newsgroups.

| Identity              | Posts in repo-alice          | Posts in repo-bob            |
|-----------------------|------------------------------|------------------------------|
| `alice@example.com`   | comp.lang.lua, sci.crypt, alt.test |                              |
| `bob@example.com`     |                              | rec.music, rec.music.synth   |
| `carol@example.com`   | comp.lang.lua, alt.test.flood | rec.music                   |
| `dave@example.com`    | sci.crypt, sci.crypt.random  | rec.music.synth              |
| `eve@example.com`     | comp.lang.lua                | rec.music                    |

- **alice** and **bob**: repo-local only (one repo each)
- **carol**, **dave**, **eve**: cross-repo (post from both machines)

This demonstrates that repos are transport, not identity.

---

## 2. Newsgroup Layout

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

## 3. Filename Convention

To avoid collisions without coordination, each peer owns a trailing digit:

- **Repo-alice**: all filenames end in `1` → `11, 21, 31, 41, ...`
- **Repo-bob**: all filenames end in `2` → `12, 22, 32, 42, ...`

The last digit is the **peer ID**, the prefix is a local counter. Two peers can never produce the same filename. Scales to 10 peers (digits 0–9).

The trailing digit identifies the **repo of origin**, not the author. Carol posting from repo-alice gets a `*1` filename; Carol posting from repo-bob gets a `*2` filename.

---

## 4. Directory Structure

Each newsgroup is a directory. Messages are numbered files using the trailing-digit scheme.

```
repo-alice/
  comp.lang.lua/
    11              ← alice          (thread 1 root)
    21              ← carol          (thread 1 reply)
    31              ← eve
  sci.crypt/
    11              ← alice
    21              ← dave
  sci.crypt.random/
    11              ← dave
  alt.test/
    11              ← alice
    21              ← carol
  alt.test.flood/
    11              ← carol

repo-bob/
  comp.lang.lua/
    (empty — will receive from repo-alice via sync)
  sci.crypt/
    (empty)
  sci.crypt.random/
    (empty)
  rec.music/
    12              ← bob            (thread 2 root)
    22              ← carol          (thread 2 reply)
    32              ← eve
  rec.music.synth/
    12              ← bob            (thread 3 root)
    22              ← dave           (thread 3 reply)
```

Repo-bob starts **empty in all shared groups**. This tests the "pull everything from scratch" sync path.

---

## 5. Sample Messages

Each message is a valid RFC 2822 file with Usenet-style headers. No messages repeated across repos. Authors are spread across both repos.

Three threads exist before sync, plus one cross-repo thread created in the demo:

| Thread | Newsgroup | Root → Reply | Repo |
|--------|-----------|-------------|------|
| 1 | comp.lang.lua | alice/11 → carol/21 | repo-alice (same-repo thread) |
| 2 | rec.music | bob/12 → carol/22 | repo-bob (same-repo thread) |
| 3 | rec.music.synth | bob/12 → dave/22 | repo-bob (same-repo thread) |
| 4 | comp.lang.lua | alice/11 → eve/12 | cross-repo (demo, section 9d) |

Thread 4 extends thread 1 after sync — the comp.lang.lua coroutine discussion becomes a 3-message cross-repo thread.

### Repo-alice messages (9 messages, 4 authors)

**comp.lang.lua/11** — alice
```
From: alice@example.com
Newsgroups: comp.lang.lua
Subject: Lua 5.5 coroutine changes
Message-ID: <lua-coro-01@alice>
Date: Mon, 24 Feb 2026 10:00:00 -0300

Has anyone tested the new coroutine.close() behavior in 5.5?
It seems to finalize to-be-closed variables differently.
```

**comp.lang.lua/21** — carol (thread: replies to alice/11)
```
From: carol@example.com
Newsgroups: comp.lang.lua
Subject: Re: Lua 5.5 coroutine changes
Message-ID: <lua-coro-02@carol>
Date: Mon, 24 Feb 2026 11:00:00 -0300
References: <lua-coro-01@alice>
In-Reply-To: <lua-coro-01@alice>

The new close() behavior matters a lot for game engines.
We use coroutines for NPC scripts and the finalization
order change broke some of our cleanup logic.
```

**comp.lang.lua/31** — eve
```
From: eve@example.com
Newsgroups: comp.lang.lua
Subject: Lua string patterns vs full regex
Message-ID: <lua-pattern-01@eve>
Date: Mon, 24 Feb 2026 12:00:00 -0300

I keep running into limitations with Lua's built-in patterns.
No alternation, no non-greedy quantifiers. Is LPeg the only
real alternative, or are there lighter options?
```

**sci.crypt/11** — alice
```
From: alice@example.com
Newsgroups: sci.crypt
Subject: Post-quantum key exchange in practice
Message-ID: <crypt-pq-01@alice>
Date: Mon, 24 Feb 2026 13:00:00 -0300

ML-KEM is now in TLS 1.3 drafts. Anyone deploying hybrid
key exchange (X25519 + ML-KEM-768) in production?
```

**sci.crypt/21** — dave
```
From: dave@example.com
Newsgroups: sci.crypt
Subject: Side-channel attacks on AES-NI
Message-ID: <crypt-aes-01@dave>
Date: Mon, 24 Feb 2026 14:00:00 -0300

The recent paper on power analysis against AES-NI is
concerning. Even hardware instructions aren't immune to
side-channel leakage if the key schedule is exposed.
```

**sci.crypt.random/11** — dave
```
From: dave@example.com
Newsgroups: sci.crypt.random
Subject: CSPRNG seeding on embedded Linux
Message-ID: <random-seed-01@dave>
Date: Mon, 24 Feb 2026 15:00:00 -0300

On embedded systems with no RTC, getrandom(2) blocks until
the entropy pool is initialized. What do people use for
early-boot randomness?
```

**alt.test/11** — alice
```
From: alice@example.com
Newsgroups: alt.test
Subject: Testing MH format with git
Message-ID: <test-mh-01@alice>
Date: Mon, 24 Feb 2026 16:00:00 -0300

This is a test message to verify MH file handling in git.
If you can read this, the format works.
```

**alt.test/21** — carol
```
From: carol@example.com
Newsgroups: alt.test
Subject: Cross-repo sync test
Message-ID: <test-sync-01@carol>
Date: Mon, 24 Feb 2026 16:30:00 -0300

Testing that messages from different authors survive
a git pull across repos. Carol posting from repo-alice.
```

**alt.test.flood/11** — carol
```
From: carol@example.com
Newsgroups: alt.test.flood
Subject: Flood test #1
Message-ID: <flood-01@carol>
Date: Mon, 24 Feb 2026 17:00:00 -0300

First message in the flood test group.
Used for volume/stress testing.
```

### Repo-bob messages (5 messages, 4 authors)

**rec.music/12** — bob
```
From: bob@example.com
Newsgroups: rec.music
Subject: Analog vs digital synthesis in 2026
Message-ID: <music-analog-01@bob>
Date: Tue, 25 Feb 2026 09:00:00 -0300

With modern DACs and oversampling, can anyone actually
hear the difference between analog and digital oscillators
in a blind test?
```

**rec.music/22** — carol (thread: replies to bob/12)
```
From: carol@example.com
Newsgroups: rec.music
Subject: Re: Analog vs digital synthesis in 2026
Message-ID: <music-analog-02@carol>
Date: Tue, 25 Feb 2026 10:00:00 -0300
References: <music-analog-01@bob>
In-Reply-To: <music-analog-01@bob>

I did a blind test last month — 20 listeners, A/B between
a Moog and a software clone. 60% accuracy, barely above
chance. The analog "warmth" might be nostalgia bias.
```

**rec.music/32** — eve
```
From: eve@example.com
Newsgroups: rec.music
Subject: Microtonal tuning systems
Message-ID: <music-micro-01@eve>
Date: Tue, 25 Feb 2026 11:00:00 -0300

Has anyone experimented with 19-TET or 31-TET tuning?
Most DAWs are locked to 12-TET. I've been using Scala
files but the workflow is painful.
```

**rec.music.synth/12** — bob
```
From: bob@example.com
Newsgroups: rec.music.synth
Subject: Modular synth patching as a graph problem
Message-ID: <synth-graph-01@bob>
Date: Tue, 25 Feb 2026 12:00:00 -0300

Every modular synth patch is a directed graph. Has anyone
applied graph theory to find optimal signal routing?
```

**rec.music.synth/22** — dave (thread: replies to bob/12)
```
From: dave@example.com
Newsgroups: rec.music.synth
Subject: Re: Modular synth patching as a graph problem
Message-ID: <synth-graph-02@dave>
Date: Tue, 25 Feb 2026 13:00:00 -0300
References: <synth-graph-01@bob>
In-Reply-To: <synth-graph-01@bob>

I implemented exactly this on a Lattice iCE40 FPGA.
The routing matrix is a sparse adjacency list — each
module has 4 inputs and 2 outputs. Happy to share
the Verilog if anyone wants to try it.
```

### Author summary

| Author | repo-alice msgs | repo-bob msgs | Total | Newsgroups |
|--------|:-:|:-:|:-:|---|
| alice  | 3 | 0 | 3 | comp.lang.lua, sci.crypt, alt.test |
| bob    | 0 | 2 | 2 | rec.music, rec.music.synth |
| carol  | 3 | 1 | 4 | comp.lang.lua, alt.test, alt.test.flood, rec.music |
| dave   | 2 | 1 | 3 | sci.crypt, sci.crypt.random, rec.music.synth |
| eve    | 1 | 1 | 2 | comp.lang.lua, rec.music |

---

## 6. Repo Initialization

No bare hub repo. Both repos are regular git repos that pull from each other using `file://` paths. No daemon needed.

### Step 6a: Create repo-alice

```bash
mkdir -p ~/exps-newsgroups-lab/repo-alice
cd ~/exps-newsgroups-lab/repo-alice
git init

# Create newsgroup directories and populate messages
mkdir -p comp.lang.lua sci.crypt sci.crypt.random alt.test alt.test.flood

# Write all repo-alice messages (see section 5) into the directories
# ... (each message written as the numbered file)

git add .
git commit -m "repo-alice: initial messages (alice, carol, dave, eve)"
```

### Step 6b: Create repo-bob

```bash
mkdir -p ~/exps-newsgroups-lab/repo-bob
cd ~/exps-newsgroups-lab/repo-bob
git init

# Create bob-only directories with messages
mkdir -p rec.music rec.music.synth

# Write all repo-bob messages (see section 5) into the directories
# ... (each message written as the numbered file)

# Create empty shared directories (so Claws sees the folders)
mkdir -p comp.lang.lua sci.crypt sci.crypt.random

git add .
git commit -m "repo-bob: initial messages (bob, carol, dave, eve)"
```

### Step 6c: Add cross-remotes

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

## 7. Sync Script

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

## 8. Claws Mail Configuration

Claws Mail reads MH folders directly from the filesystem. Each repo appears as a separate "mailbox" (account folder tree).

### Step 8a: Add repo-alice as a mailbox

1. Open Claws Mail
2. Go to **File → Add mailbox → MH...**
3. In the dialog, enter the path: `~/exps-newsgroups-lab/repo-alice`
4. Click OK
5. The folder tree appears in the left pane with:
   ```
   repo-alice
   ├── alt.test          (2 messages: alice, carol)
   ├── alt.test.flood    (1 message: carol)
   ├── comp.lang.lua     (3 messages: alice, carol, eve)
   ├── sci.crypt         (2 messages: alice, dave)
   └── sci.crypt.random  (1 message: dave)
   ```

### Step 8b: Add repo-bob as a mailbox

1. Go to **File → Add mailbox → MH...**
2. Enter the path: `~/exps-newsgroups-lab/repo-bob`
3. Click OK
4. The folder tree appears:
   ```
   repo-bob
   ├── comp.lang.lua     (0 messages — empty, pre-sync)
   ├── rec.music         (3 messages: bob, carol, eve)
   ├── rec.music.synth   (2 messages: bob, dave)
   ├── sci.crypt         (0 messages — empty, pre-sync)
   └── sci.crypt.random  (0 messages — empty, pre-sync)
   ```

### Step 8c: Verify display

- Click on `repo-alice/comp.lang.lua` — should show 3 messages from 3 different people
- Click on `repo-bob/comp.lang.lua` — should show 0 messages
- Click on `repo-bob/rec.music` — should show 3 messages from 3 different people
- Both mailbox trees are visible simultaneously in the folder pane

---

## 9. Live Sync Demo

### Step 9a: Start the sync watcher on Bob's side

```bash
cd ~/exps-newsgroups-lab/repo-bob
bash watch-sync.sh alice 5
```

This pulls from alice every 5 seconds via `file://`.

### Step 9b: Trigger a sync

Alice's repo already has messages committed. The watcher in repo-bob pulls them automatically on the next cycle.

Within 5 seconds, `watch-sync.sh` in repo-bob pulls alice's messages into the shared groups.

### Step 9c: Refresh Claws Mail

Claws does not auto-detect filesystem changes. After sync:

- Right-click `repo-bob` in the folder pane → **Check for new messages**
- Or press the global **Get Mail** button (it checks all accounts/mailboxes)
- Or set up a **folder processing rule** to auto-check at an interval

After refresh, `repo-bob/comp.lang.lua` now shows 3 messages (alice, carol, eve — all from repo-alice), while `repo-bob/rec.music` still has 3 (bob, carol, eve — originals from repo-bob).

Note: carol and eve now appear in **both** repos — their messages originated on different machines but converge after sync.

### Step 9d: Verify bidirectional sync

```bash
# On bob's side, eve posts a reply (note: filename ends in 2, it's repo-bob)
cat > ~/exps-newsgroups-lab/repo-bob/comp.lang.lua/12 << 'EOF'
From: eve@example.com
Newsgroups: comp.lang.lua
Subject: Re: Lua 5.5 coroutine changes
Message-ID: <lua-coro-03@eve>
Date: Tue, 25 Feb 2026 14:00:00 -0300
References: <lua-coro-01@alice> <lua-coro-02@carol>
In-Reply-To: <lua-coro-01@alice>

Yes, I tested it. The finalization order changed in 5.5.
to-be-closed variables now close in reverse declaration order
within the same scope level.
EOF

cd ~/exps-newsgroups-lab/repo-bob
git add .
git commit -m "eve: reply to lua coroutine thread"
```

Then on alice's side, pull from bob:

```bash
cd ~/exps-newsgroups-lab/repo-alice
git pull bob main
```

Refresh Claws on alice's mailbox — `comp.lang.lua` now shows 4 messages (11, 21, 31 from repo-alice + 12 from repo-bob). In threaded view, Claws groups them:

```
▼ Lua 5.5 coroutine changes         alice   (11, root)
  ├─ Re: Lua 5.5 coroutine changes  carol   (21, from repo-alice)
  └─ Re: Lua 5.5 coroutine changes  eve     (12, from repo-bob)
  Lua string patterns vs full regex  eve     (31, standalone)
```

The thread spans two repos and three authors — eve's reply came from repo-bob but threads correctly because of the `References:` header.

---

## 10. What This Proves

After running this experiment:

- **Repos are not identities**: carol, dave, and eve post from both repos — the repo is just transport
- **Threading works across repos**: the comp.lang.lua coroutine thread spans repo-alice and repo-bob, with Claws grouping them correctly via `References:`/`In-Reply-To:` headers
- **MH + git works**: plain numbered files in directories, version-controlled, mergeable
- **Claws reads it natively**: no import, no conversion, just point at the directory
- **file:// sync is trivial**: `git pull` between local repos, no server or daemon
- **Trailing-digit scheme prevents collisions**: repo-alice's `*1` files never clash with repo-bob's `*2` files
- **Bidirectional sync**: both peers can create messages and pull from each other
- **Live updates**: Claws picks up new files on refresh
- **Hierarchy preserved**: `sci.crypt/` and `sci.crypt.random/` appear as sibling folders

### Limitations of this simple setup

- **Trailing-digit numbering is peer-count-limited** — works for up to 10 peers. The timestamp+hash scheme from `all.md` removes this limit.
- **No deduplication** — not needed here (unique filenames by construction), but a real system needs it.
- **Manual git operations** — no daemon, no hooks, just scripts. A real setup would use git hooks or inotify.
- **No signing, no content addressing** — this is intentionally the simplest possible layer. Freechains properties come later.
- **Empty directories require a placeholder** — git doesn't track empty directories. Either add a `.gitkeep` or ensure Claws creates `.mh_sequences` on first access.
