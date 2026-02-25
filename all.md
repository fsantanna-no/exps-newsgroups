# Newsgroup + MH + Git + Freechains: Architecture Findings

## Context

Exploring how to unify local email (MH format, Claws Mail) with Usenet newsgroups, git version control, and GPG signing, as a foundation for a verifiable, transport-agnostic messaging architecture convergent with Freechains.

---

## MH Format

- MH stores each message as a **numbered plain text file** in a directory (`~/Mail/inbox/1`, `~/Mail/inbox/2`, etc.)
- Git-friendly by design — no conversion needed
- **Claws Mail uses MH as its native storage format**
- Per the nmh spec: *"The file name is a positive integer. All files that are not positive integers must be ignored by a MH-compatible implementation."*
- Non-integer files are silently ignored — useful for sidecar files (`.hash-map`, etc.)

---

## The Shared Newsgroup Problem

MH numbering is **local and sequential** — numbers have no global meaning. The same article may be `47` on one machine and `312` on another. You cannot `git push` two MH newsgroup folders directly by filename without collision.

**Solution used by leafnode/NNTP clients**: maintain a `Message-ID → local number` mapping. The local number is a disposable alias; the Message-ID (or content hash) is the canonical identity.

---

## Claws Mail Integer Size: CRITICAL CONSTRAINT

From source code (`procmsg.h`, `imap.h`): `msginfo->msgnum` is typed as **`gint`** (GLib's 32-bit signed int).

- **Max value: 2,147,483,647 (10 digits)**
- This rules out any scheme requiring 11+ digits
- A plain Unix timestamp (10 digits, currently ~1.7B) already approaches the limit and leaves no room for a hash suffix

---

## Timestamp + Hash Filename Scheme

Encode both temporal order and global identity into a single integer that fits in 32 bits.

### Formula

```
msgnum = time_units_since_epoch * SLOTS + hash_mod_SLOTS
```

### Epoch

**Jan 1, 2025** = Unix timestamp `1735689600`

---

## Candidate Schemes (all fit in 32-bit gint)

### Option A: Days + 5 hash digits (recommended)

```
msgnum = days_since_2025 * 100000 + hash5
```

| Property | Value |
|---|---|
| Time digits | 5 (days) |
| Hash digits | 5 |
| Total digits | 10 |
| Coverage | 50 years → year 2075 |
| Hash slots/day | 100,000 |
| Max value | 18,263 × 99,999 = 1,826,281,737 ✓ |
| Collision chance | negligible even for high-volume groups |

**Best overall**: day granularity is sufficient for newsreader ordering, 100k slots/day makes collision essentially impossible.

### Option B: Hours + 3 hash digits

```
msgnum = hours_since_2025 * 1000 + hash3
```

| Property | Value |
|---|---|
| Time digits | 6 (hours) |
| Hash digits | 3 |
| Total digits | 9 |
| Coverage | 50 years → year 2075 |
| Hash slots/hour | 1,000 |
| Max value | 438,300 × 999 = 437,861,700 ✓ |
| Collision chance | ~0.05% at 1 article/min |

**Best if sub-day ordering matters.**

### Option C: Minutes + ~81 slots (not recommended)

50 years of minutes = ~26.3M, leaving only 81 hash slots. Requires `mod 81` — inelegant and fragile.

---

## Implementation

### Days scheme

```bash
EPOCH=1735689600
now=$(date +%s)
days=$(( (now - EPOCH) / 86400 ))
hash5=$(echo -n "$message_id" | sha256sum | tr -dc '0-9' | cut -c1-5)
msgnum=$(( days * 100000 + hash5 ))
```

### Hours scheme

```bash
EPOCH=1735689600
now=$(date +%s)
hours=$(( (now - EPOCH) / 3600 ))
hash3=$(echo -n "$message_id" | sha256sum | tr -dc '0-9' | cut -c1-3)
msgnum=$(( hours * 1000 + hash3 ))
```

### Properties of both schemes

- **Monotonically increasing**: temporal order preserved, `next`/`prev`/`scan` work correctly in Claws
- **Globally deterministic**: same article on two machines → same integer → git merges conflict-free
- **Deduplication without sidecar**: if file already exists with that name, it's the same article
- **No map needed**: filename encodes both identity and order

---

## Folder Structure

```
~/Mail/
  sent/                        ← email out (MH, git-tracked)
  received/                    ← email in (MH, git-tracked)
  news/
    comp.lang.lua/
      1735000123456            ← days*100000 + hash5 filename
      1735000287341
      .mh_sequences            ← MH sidecar, ignored as non-integer
```

---

## Client Compatibility

### Claws Mail
- Native MH, reads integer filenames correctly
- Built-in NNTP support — articles land in MH folders
- `gint` (32-bit) constraint is the binding limit
- **Recommended client for this architecture**

### Maildir alternatives
- No mainstream newsreader stores natively to standard Maildir
- **Thunderbird**: has "maildir-lite" (one file per message) but it is NOT standard Maildir — cannot be shared with other tools, flags not stored in filenames, still experimental/buggy
- **Gnus (Emacs)**: the only client with true `nnmaildir` backend supporting arbitrary filenames — but requires Emacs

### Newsreaders and their storage

| Client | Storage | Maildir? | MH? |
|---|---|---|---|
| Claws Mail | MH (native) | No | ✓ |
| Thunderbird | mbox/maildir-lite | lite only | No |
| NeoMutt | NNTP cache | No | via patch |
| Gnus | nnmaildir/nnml | ✓ (nnmaildir) | No |
| Pan | own binary cache | No | No |
| slrn | NNTP spool | via symlink hack | No |
| tin | own spool | No | No |

---

## Sync Architecture

```
Freechains / git          ← canonical, content-addressed
      ↓
  sync script             ← deduplicates by Message-ID/hash, assigns msgnum
      ↓
  MH folders              ← local client view, rebuildable
      ↓
  Claws Mail              ← reads MH normally, knows nothing of hashes
```

The MH numbers are a **rebuildable cache** of the canonical store, not the store itself.

---

## Leafnode Role

Leafnode is a local NNTP server that:
- Fetches articles from upstream (or git peer) and serves `localhost:119`
- Already solves the `Message-ID → local number` mapping problem internally
- Claws connects to it as a normal NNTP server
- In the target architecture: replace its upstream (real Usenet) with a git-based peer

```
Claws Mail → localhost:119 → Leafnode → git/Freechains peer
```

---

## Convergence with Freechains

| Property | Email | Usenet | Freechains | This architecture |
|---|---|---|---|---|
| Content addressing | ✗ | ✗ | ✓ | ✓ (hash in filename) |
| Mandatory signing | ✗ | ✗ | ✓ | ✓ (GPG commit) |
| Immutability | sort of | ✗ (cancel) | ✓ | ✓ (git) |
| Spam resistance | ✗ | ✗ | ✓ (consensus) | partial |
| Decentralized | federated | federated | p2p | p2p via git |

A Freechains block, stored as a git blob, delivered via NNTP headers, viewed in Claws via MH — same object in three protocol dialects.

---

## Open Questions

- Verify `gint` assumption against latest Claws source (the constraint is critical)
- Leafnode peering over git push/pull instead of NNTP
- GPG signing integration at the git commit layer for newsgroup posts
- Freechains chain ↔ newsgroup namespace mapping
