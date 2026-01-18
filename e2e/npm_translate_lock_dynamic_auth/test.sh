#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

BZLMOD_FLAG="${BZLMOD_FLAG:---enable_bzlmod=1}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}Testing Dynamic .npmrc Authentication${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

if [ -z "${ASPECT_NPM_AUTH_TOKEN:-}" ]; then
    echo -e "${YELLOW}Skipping test: ASPECT_NPM_AUTH_TOKEN not set${NC}"
    exit 0
fi

if [ -f ~/.npmrc ]; then
    cp ~/.npmrc ~/.npmrc.backup
    HAS_BACKUP=true
else
    HAS_BACKUP=false
fi

cleanup() {
    echo ""
    echo -e "${YELLOW}Cleaning up...${NC}"
    if [ "$HAS_BACKUP" = true ]; then
        mv ~/.npmrc.backup ~/.npmrc
        echo -e "${GREEN}Restored ~/.npmrc${NC}"
    elif [ -f ~/.npmrc.test ]; then
        rm ~/.npmrc
        echo -e "${GREEN}Removed test ~/.npmrc${NC}"
    fi
}

trap cleanup EXIT

echo -e "${BLUE}Test 1: Fetch with valid token${NC}"
cat >~/.npmrc <<EOF
_authToken=${ASPECT_NPM_AUTH_TOKEN}
EOF
touch ~/.npmrc.test

bazel clean --expunge "$BZLMOD_FLAG"
if bazel fetch "$BZLMOD_FLAG" //... 2>&1 | tee /tmp/fetch.log; then
    echo -e "${GREEN}✓ Fetch with valid token succeeded${NC}"
else
    echo -e "${RED}✗ Fetch with valid token failed${NC}"
    cat /tmp/fetch.log
    exit 1
fi
echo ""

echo -e "${BLUE}Test 2: Fetch with broken token (empty repository cache)${NC}"
cat >~/.npmrc <<EOF
_authToken=BROKEN_TOKEN_SHOULD_CAUSE_401
EOF

if bazel fetch "$BZLMOD_FLAG" --repository_cache= //... 2>&1 | tee /tmp/fetch_broken.log; then
    if grep -qi "401\|unauthorized" /tmp/fetch_broken.log; then
        echo -e "${GREEN}✓✓✓ Got 401 with broken token - dynamic auth confirmed!${NC}"
    else
        echo -e "${RED}✗ Fetch succeeded with broken token (auth is cached, not dynamic!)${NC}"
        exit 1
    fi
else
    if grep -qi "401\|unauthorized" /tmp/fetch_broken.log; then
        echo -e "${GREEN}✓✓✓ Got 401 with broken token - dynamic auth confirmed!${NC}"
    else
        echo -e "${RED}✗ Fetch failed but not with 401${NC}"
        tail -20 /tmp/fetch_broken.log
        exit 1
    fi
fi
echo ""

echo -e "${BLUE}Test 3: Fetch with restored valid token${NC}"
cat >~/.npmrc <<EOF
_authToken=${ASPECT_NPM_AUTH_TOKEN}
EOF

if bazel fetch "$BZLMOD_FLAG" --repository_cache= //... 2>&1; then
    echo -e "${GREEN}✓ Fetch with restored token succeeded${NC}"
else
    echo -e "${RED}✗ Fetch with restored token failed${NC}"
    exit 1
fi
echo ""

echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}✅ All dynamic auth tests passed!${NC}"
echo -e "${GREEN}================================================================${NC}"
