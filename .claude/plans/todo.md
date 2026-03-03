# Plan: Implement repos.md Two-Repo Sync Experiment

## Context

Two local git repos with MH newsgroup messages,
linked as peers via `file://` remotes, inside
`repos/`.
A third repo (`repo-0`) is a fixed sample tracked
in the outer exps repo.

All sync and Claws Mail steps are manual.
Step 9d (eve's cross-repo reply) is a live demo.

## Reference

- `repos.md` sections 1–6

## Decisions

- **Directory layout**: hierarchical
  (`comp.lang.lua` → `comp/lang/lua/`)
- **repo-0**: fixed sample, tracked in outer exps
  repo, no inner git
- **repo-1 / repo-2**: independent git repos,
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
| 1 | repo-0 dirs + .gitkeep (5 newsgroup dirs) |
| 2 | repo-0 comp/lang/lua messages (11, 21, 31) |
| — | repos.md formatting (80-col, tables, phrases) |
| — | outer .gitignore: `repos/repo-1/`, `repos/repo-2/` |
| — | repo-1 created by user: git init, 3 msgs, pushed to GitHub |
| — | repo-1 .gitignore removed (moved to .git/info/exclude) |
| — | repo-2 created by user: git init, synced from repo-1, pushed to GitHub |
| — | repo-2 peer-1 remote → `file:///x/freechains/repos/repo-1` |
| — | Claws Mail: repo-1 and repo-2 added as MH mailboxes |

### TODO

| # | What | Details |
|----|------|---------|
| 3 | repo-1 sci/crypt messages | sci/crypt/11, 21 + sci/crypt/random/11 |
| 4 | repo-1 alt/test messages | alt/test/11, 21 + alt/test/flood/11 |
| — | commit + push repo-1 | 6 new messages |
| — | sync repo-2 ← repo-1 | `git pull peer-1 main` |
| 7 | repo-2 rec/music messages | rec/music/12, 22, 32 |
| 8 | repo-2 rec/music/synth messages | rec/music/synth/12, 22 |
| — | commit + push repo-2 | 5 new messages |
| — | sync repo-1 ← repo-2 | add peer-2 remote, pull |
| — | .git/info/exclude | add Claws rules to both repos |
| — | Claws verify | refresh both, check threading |
| 12 | Claws Mail instructions | document setup for README |

---

## Current State

### Outer exps repo
- Branch: `worktree-todo`
- Tracks: `repos/repo-0/` (fixed sample)
- Ignores: `repos/repo-1/`, `repos/repo-2/`

### repo-1
- Branch: main, 2 commits
- Remote: `origin` → `git@github.com:fsantanna-no/exps-newsgroups-repo-1.git`
- No peer remote yet
- Files: 5 .gitkeep + 3 messages (comp/lang/lua)
- Missing: 6 messages (sci/crypt, alt/test)
- Missing: `.git/info/exclude` Claws rules

### repo-2
- Branch: main, 2 commits (synced from repo-1)
- Remotes: `origin` → GitHub, `peer-1` → `file:///x/freechains/repos/repo-1`
- Files: same as repo-1 (synced)
- Missing: 5 own messages (rec/music, rec/music/synth)
- Missing: `.git/info/exclude` Claws rules

### Claws Mail
- Both repos added as MH mailboxes
- comp/lang/lua shows 3 messages with threading
