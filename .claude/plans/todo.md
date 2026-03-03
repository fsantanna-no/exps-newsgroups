# Plan: Implement repos.md Two-Repo Sync Experiment

## Context

Two local git repos with MH newsgroup messages,
linked as peers via `file://` remotes, inside
`peers/`.
A third repo (`peer-0`) is a fixed sample tracked
in the outer exps repo.

All sync and Claws Mail steps are manual.
Step 9d (eve's cross-repo reply) is a live demo.

## Reference

- `repos.md` sections 1–6

## Decisions

- **Directory layout**: hierarchical
  (`comp.lang.lua` → `comp/lang/lua/`)
- **peer-0**: fixed sample, tracked in outer exps
  repo, no inner git
- **peer-1 / peer-2**: independent git repos,
  gitignored by outer exps repo
- **No `.gitignore` in repo-X**: use
  `.git/info/exclude` for Claws artifacts instead
- **Claws artifacts to exclude**: `.claws_cache`,
  `.claws_mark`, `.mh_sequences`, `*.swp`,
  `inbox/`, `draft/`, `sent/`, `queue/`, `trash/`
- **Claws folder detection**: manual
  ("Check for new folders") — only needed once if
  dirs pre-exist via `.gitkeep`

---

## Progress

### DONE

| # | What |
|----|------|
| 1 | peer-0 dirs + .gitkeep (5 newsgroup dirs) |
| 2 | peer-0 comp/lang/lua messages (11, 21, 31) |
| — | repos.md formatting (80-col, tables, phrases) |
| — | outer .gitignore: `peers/peer-1/`, `peers/peer-2/` |
| — | peer-1 created by user: git init, 3 msgs, pushed to GitHub |
| — | peer-1 .gitignore removed (moved to .git/info/exclude) |
| — | peer-2 created by user: git init, synced from peer-1, pushed to GitHub |
| — | peer-2 remote peer-1 → `file:///x/freechains/peers/peer-1` |
| — | Claws Mail: peer-1 and peer-2 added as MH mailboxes |
| — | renamed repos/ → peers/, repo-X → peer-X |

### TODO

| # | What | Details |
|----|------|---------|
| 3 | peer-1 sci/crypt messages | sci/crypt/11, 21 + sci/crypt/random/11 |
| 4 | peer-1 alt/test messages | alt/test/11, 21 + alt/test/flood/11 |
| — | commit + push peer-1 | 6 new messages |
| — | sync peer-2 ← peer-1 | `git pull peer-1 main` |
| 7 | peer-2 rec/music messages | rec/music/12, 22, 32 |
| 8 | peer-2 rec/music/synth messages | rec/music/synth/12, 22 |
| — | commit + push peer-2 | 5 new messages |
| — | sync peer-1 ← peer-2 | add peer-2 remote, pull |
| — | .git/info/exclude | add Claws rules to both repos |
| — | Claws verify | refresh both, check threading |
| 12 | Claws Mail instructions | document setup for README |

---

## Current State

### Outer exps repo
- Branch: main
- Tracks: `peers/peer-0/` (fixed sample)
- Ignores: `peers/peer-1/`, `peers/peer-2/`

### peer-1 (`/x/freechains/peers/peer-1`)
- Branch: main, 2 commits
- Remote: `origin` → GitHub
- No peer remote yet
- Files: 5 .gitkeep + 3 messages (comp/lang/lua)
- Missing: 6 messages (sci/crypt, alt/test)
- Missing: `.git/info/exclude` Claws rules

### peer-2 (`/x/freechains/peers/peer-2`)
- Branch: main, 2 commits (synced from peer-1)
- Remotes: `origin` → GitHub,
  `peer-1` → `file:///x/freechains/peers/peer-1`
- Files: same as peer-1 (synced)
- Missing: 5 own messages (rec/music, rec/music/synth)
- Missing: `.git/info/exclude` Claws rules

### Claws Mail
- Both peers added as MH mailboxes
- comp/lang/lua shows 3 messages with threading
