# Plan: Implement repos.md Two-Repo Sync Experiment

## Status: IN PROGRESS

## Decision Log

- **Directory layout**: hierarchical (dots → `/`), matching
  real NNTP spool layout. `comp.lang.lua` → `comp/lang/lua/`.
  RFC 2822 `Newsgroups:` headers keep dot notation.
- **Non-leaf groups accept posts**: unlike traditional Usenet
  (where only leaves carry articles), our experiment allows
  non-leaf directories to hold both messages and subdirs.
  E.g., `sci/crypt/` holds articles 11, 21 AND contains
  `random/`. This is an intentional extension — the NNTP
  `active` file is a flat list with no hierarchy enforcement,
  so nothing in the protocol prevents it. MH and Claws Mail
  handle it natively.
  Affected groups: `sci.crypt`, `alt.test`, `rec.music`.
- **`.gitkeep` in all newsgroup dirs**: every newsgroup
  directory (leaf or not) gets a `.gitkeep` so the outer
  repo tracks the empty skeleton before messages are added.

---

## Steps

### Step 1: Create repo-1 directory structure + .gitkeep

```
repos/repo-1/
  comp/lang/lua/.gitkeep
  sci/crypt/.gitkeep
  sci/crypt/random/.gitkeep
  alt/test/.gitkeep
  alt/test/flood/.gitkeep
```

Add `.gitkeep` to all 5 newsgroup dirs (leaves and non-leaves
that accept posts).

**Verify**: `find repos/repo-1 -name .gitkeep | sort`

---

### Step 2: Write repo-1 messages (comp/lang/lua)

3 files in `repos/repo-1/comp/lang/lua/`:

- `11` — alice: "Lua 5.5 coroutine changes"
- `21` — carol: "Re: Lua 5.5 coroutine changes"
  (References alice)
- `31` — eve: "Lua string patterns vs full regex"

Content from repos.md section 5 (headers unchanged —
`Newsgroups: comp.lang.lua` stays dot-separated).

---

### Step 3: Write repo-1 messages (sci/crypt, sci/crypt/random)

3 files:

- `repos/repo-1/sci/crypt/11` — alice: "Post-quantum key
  exchange"
- `repos/repo-1/sci/crypt/21` — dave: "Side-channel attacks
  on AES-NI"
- `repos/repo-1/sci/crypt/random/11` — dave: "CSPRNG seeding"

---

### Step 4: Write repo-1 messages (alt/test, alt/test/flood)

3 files:

- `repos/repo-1/alt/test/11` — alice: "Testing MH format
  with git"
- `repos/repo-1/alt/test/21` — carol: "Cross-repo sync test"
- `repos/repo-1/alt/test/flood/11` — carol: "Flood test #1"

**Total**: 9 messages in repo-1.

---

### Step 5: Initialize repo-1 as a git repo

```bash
cd repos/repo-1
git init
git add .
git commit -m "repo-1: initial messages (alice, carol, dave, eve)"
```

---

### Step 6: Create repo-2 directory structure + .gitkeep

```
repos/repo-2/
  comp/lang/lua/.gitkeep
  sci/crypt/.gitkeep
  sci/crypt/random/.gitkeep
  rec/music/.gitkeep
  rec/music/synth/.gitkeep
```

All 5 newsgroup dirs get `.gitkeep`.

---

### Step 7: Write repo-2 messages (rec/music)

3 files in `repos/repo-2/rec/music/`:

- `12` — bob: "Analog vs digital synthesis"
- `22` — carol: "Re: Analog vs digital" (References bob)
- `32` — eve: "Microtonal tuning systems"

---

### Step 8: Write repo-2 messages (rec/music/synth)

2 files in `repos/repo-2/rec/music/synth/`:

- `12` — bob: "Modular synth patching"
- `22` — dave: "Re: Modular synth" (References bob)

**Total**: 5 messages in repo-2.

---

### Step 9: Initialize repo-2 as a git repo

```bash
cd repos/repo-2
git init
git add .
git commit -m "repo-2: initial messages (bob, carol, dave, eve)"
```

---

### Step 10: Add cross-remotes

```bash
cd repos/repo-1
git remote add peer-2 file://$(realpath ../repo-2)

cd repos/repo-2
git remote add peer-1 file://$(realpath ../repo-1)
```

---

### Step 11: Manual sync test (repo-2 pulls from repo-1)

```bash
cd repos/repo-2
git pull --no-edit peer-1 main
```

**Verify**:
- `repos/repo-2/comp/lang/lua/` now has 11, 21, 31
- `repos/repo-2/sci/crypt/` now has 11, 21
- `repos/repo-2/sci/crypt/random/` now has 11
- repo-2 total: 14 messages (5 own + 9 from repo-1)

---

### Step 12: Claws Mail setup (manual instructions)

Document for user:

1. File → Add mailbox → MH → path: `<abs>/repos/repo-1`
2. File → Add mailbox → MH → path: `<abs>/repos/repo-2`
3. Folder tree shows hierarchical layout:
   ```
   repo-1
   ├── alt
   │   └── test        (2 msgs)
   │       └── flood   (1 msg)
   ├── comp
   │   └── lang
   │       └── lua     (3 msgs)
   └── sci
       └── crypt       (2 msgs)
           └── random  (1 msg)
   ```
4. Enable threaded view → verify threads

---

## Summary

| Step | What                      | Artifact       |
|------|---------------------------|----------------|
| 1    | repo-1 dirs               | 5 leaf dirs    |
| 2    | repo-1 comp/lang/lua msgs | 3 files        |
| 3    | repo-1 sci/crypt msgs     | 3 files        |
| 4    | repo-1 alt/test msgs      | 3 files        |
| 5    | git init repo-1           | —              |
| 6    | repo-2 dirs               | 5 leaf dirs    |
| 7    | repo-2 rec/music msgs     | 3 files        |
| 8    | repo-2 rec/music/synth    | 2 files        |
| 9    | git init repo-2           | —              |
| 10   | cross-remotes             | —              |
| 11   | sync test                 | —              |
| 12   | Claws Mail instructions   | —              |
