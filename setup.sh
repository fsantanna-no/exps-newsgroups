#!/bin/bash
# setup.sh — Create repo-1 and repo-2 for the newsgroup experiment
# Run from the project root: bash setup.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ----------------------------------------------------------
# 1. Clean slate
# ----------------------------------------------------------

for repo in repo-1 repo-2; do
    if [ -d "$repo" ]; then
        echo "WARNING: removing existing $repo/"
        rm -rf "$repo"
    fi
done

# ----------------------------------------------------------
# 2. Create repo-1
# ----------------------------------------------------------

git init -b main repo-1
cd repo-1
git config commit.gpgSign false

mkdir -p comp.lang.lua sci.crypt sci.crypt.random \
         alt.test alt.test.flood

# comp.lang.lua/11 — alice
cat > comp.lang.lua/11 << 'EOF'
From: alice@example.com
Newsgroups: comp.lang.lua
Subject: Lua 5.5 coroutine changes
Message-ID: <lua-coro-01@alice>
Date: Mon, 24 Feb 2026 10:00:00 -0300

Has anyone tested the new coroutine.close() behavior in 5.5?
It seems to finalize to-be-closed variables differently.
EOF

# comp.lang.lua/21 — carol (replies to alice/11)
cat > comp.lang.lua/21 << 'EOF'
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
EOF

# comp.lang.lua/31 — eve
cat > comp.lang.lua/31 << 'EOF'
From: eve@example.com
Newsgroups: comp.lang.lua
Subject: Lua string patterns vs full regex
Message-ID: <lua-pattern-01@eve>
Date: Mon, 24 Feb 2026 12:00:00 -0300

I keep running into limitations with Lua's built-in patterns.
No alternation, no non-greedy quantifiers. Is LPeg the only
real alternative, or are there lighter options?
EOF

# sci.crypt/11 — alice
cat > sci.crypt/11 << 'EOF'
From: alice@example.com
Newsgroups: sci.crypt
Subject: Post-quantum key exchange in practice
Message-ID: <crypt-pq-01@alice>
Date: Mon, 24 Feb 2026 13:00:00 -0300

ML-KEM is now in TLS 1.3 drafts. Anyone deploying hybrid
key exchange (X25519 + ML-KEM-768) in production?
EOF

# sci.crypt/21 — dave
cat > sci.crypt/21 << 'EOF'
From: dave@example.com
Newsgroups: sci.crypt
Subject: Side-channel attacks on AES-NI
Message-ID: <crypt-aes-01@dave>
Date: Mon, 24 Feb 2026 14:00:00 -0300

The recent paper on power analysis against AES-NI is
concerning. Even hardware instructions aren't immune to
side-channel leakage if the key schedule is exposed.
EOF

# sci.crypt.random/11 — dave
cat > sci.crypt.random/11 << 'EOF'
From: dave@example.com
Newsgroups: sci.crypt.random
Subject: CSPRNG seeding on embedded Linux
Message-ID: <random-seed-01@dave>
Date: Mon, 24 Feb 2026 15:00:00 -0300

On embedded systems with no RTC, getrandom(2) blocks until
the entropy pool is initialized. What do people use for
early-boot randomness?
EOF

# alt.test/11 — alice
cat > alt.test/11 << 'EOF'
From: alice@example.com
Newsgroups: alt.test
Subject: Testing MH format with git
Message-ID: <test-mh-01@alice>
Date: Mon, 24 Feb 2026 16:00:00 -0300

This is a test message to verify MH file handling in git.
If you can read this, the format works.
EOF

# alt.test/21 — carol
cat > alt.test/21 << 'EOF'
From: carol@example.com
Newsgroups: alt.test
Subject: Cross-repo sync test
Message-ID: <test-sync-01@carol>
Date: Mon, 24 Feb 2026 16:30:00 -0300

Testing that messages from different authors survive
a git pull across repos. Carol posting from repo-1.
EOF

# alt.test.flood/11 — carol
cat > alt.test.flood/11 << 'EOF'
From: carol@example.com
Newsgroups: alt.test.flood
Subject: Flood test #1
Message-ID: <flood-01@carol>
Date: Mon, 24 Feb 2026 17:00:00 -0300

First message in the flood test group.
Used for volume/stress testing.
EOF

git add .
git commit -m "repo-1: initial messages (alice, carol, dave, eve)"

cd "$SCRIPT_DIR"

# ----------------------------------------------------------
# 3. Create repo-2
# ----------------------------------------------------------

git init -b main repo-2
cd repo-2
git config commit.gpgSign false

mkdir -p rec.music rec.music.synth \
         comp.lang.lua sci.crypt sci.crypt.random

# rec.music/12 — bob
cat > rec.music/12 << 'EOF'
From: bob@example.com
Newsgroups: rec.music
Subject: Analog vs digital synthesis in 2026
Message-ID: <music-analog-01@bob>
Date: Tue, 25 Feb 2026 09:00:00 -0300

With modern DACs and oversampling, can anyone actually
hear the difference between analog and digital oscillators
in a blind test?
EOF

# rec.music/22 — carol (replies to bob/12)
cat > rec.music/22 << 'EOF'
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
EOF

# rec.music/32 — eve
cat > rec.music/32 << 'EOF'
From: eve@example.com
Newsgroups: rec.music
Subject: Microtonal tuning systems
Message-ID: <music-micro-01@eve>
Date: Tue, 25 Feb 2026 11:00:00 -0300

Has anyone experimented with 19-TET or 31-TET tuning?
Most DAWs are locked to 12-TET. I've been using Scala
files but the workflow is painful.
EOF

# rec.music.synth/12 — bob
cat > rec.music.synth/12 << 'EOF'
From: bob@example.com
Newsgroups: rec.music.synth
Subject: Modular synth patching as a graph problem
Message-ID: <synth-graph-01@bob>
Date: Tue, 25 Feb 2026 12:00:00 -0300

Every modular synth patch is a directed graph. Has anyone
applied graph theory to find optimal signal routing?
EOF

# rec.music.synth/22 — dave (replies to bob/12)
cat > rec.music.synth/22 << 'EOF'
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
EOF

# .gitkeep in empty shared dirs
touch comp.lang.lua/.gitkeep
touch sci.crypt/.gitkeep
touch sci.crypt.random/.gitkeep

git add .
git commit -m "repo-2: initial messages (bob, carol, dave, eve)"

cd "$SCRIPT_DIR"

# ----------------------------------------------------------
# 4. Cross-remotes
# ----------------------------------------------------------

git -C repo-1 remote add peer-2 \
    "file://$(realpath repo-2)"
git -C repo-2 remote add peer-1 \
    "file://$(realpath repo-1)"

echo ""
echo "=== Setup complete ==="
echo "repo-1: $(find repo-1 -maxdepth 2 -type f \
    ! -path '*/.git/*' | wc -l) message files"
echo "repo-2: $(find repo-2 -maxdepth 2 -type f \
    ! -path '*/.git/*' ! -name '.gitkeep' | wc -l) message files"
echo "repo-1 remotes:"
git -C repo-1 remote -v
echo "repo-2 remotes:"
git -C repo-2 remote -v
