#!/bin/bash

## the context of the running GitHub Action workflow will be mounted at /github/workspace
## ref: https://github.com/orgs/community/discussions/26855

### STEP 0.
echo ">>> GITHUB_WORKSPACE"
echo "$GITHUB_WORKSPACE"
cd "$GITHUB_WORKSPACE"

# print workspace and ci machine info
echo ">>> uname -a"
uname -a

echo && echo ">>> OCaml --version"
opam exec -- ocamlc --version

echo && echo ">>> Node.js --version"
node --version || echo "!WARN node is not installed"

# https://github.blog/2022-04-12-git-security-vulnerability-announced/
git config --global --add safe.directory "$(pwd)"

echo && echo ">>> git status"
git rev-parse --is-inside-work-tree && \
    git show HEAD^..HEAD --stat || git show HEAD --stat

echo && echo ">>> git ls-files"
git rev-parse --is-inside-work-tree && \
    git ls-files

### STEP 1. install dependencies
if [ "$OGA_SKIP_SETUP" == "true" ]; then
    echo && echo ">>> setup is skipped as inputs.skip-setup is set"
else
    echo && echo ">>> install OCaml dependencies (setup)"
    bash -xe -c "eval \$(opam env); $OGA_SETUP_COMMAND"
fi

### STEP 2. build
echo && echo ">>> build project"
bash -xe -c "eval \$(opam env); $OGA_BUILD_COMMAND"

### STEP 2b. build odoc if requested
if [ "$OGA_BUILD_WITH_ODOC" == "true" ]; then
    echo && echo ">>> build odoc"
    bash -xe -c "eval \$(opam env); $OGA_ODOC_BUILD_COMMAND"
    echo "odoc-site-path=_build/default/_doc/_html" >> "$GITHUB_OUTPUT"
fi

### STEP 3. test
if [ -z "$OGAI_TEST_LOG" ]; then
    OGAI_TEST_LOG="$(mktemp)"
    trap '{ rm -f -- "$OGAI_TEST_LOG" }'
fi

if [ "$OGA_SKIP_TESTING" == "true" ]; then
    echo && echo ">>> testing is skipped as inputs.skip-testing is set"
else
    echo && echo ">>> test project"
    set -o pipefail
    bash -xe -c "eval \$(opam env); $OGA_TEST_COMMAND" 2>&1 | tee "$OGAI_TEST_LOG"
    TEST_RET="$?"
    set +o pipefail
    echo "return-codes--test=$TEST_RET" >> "$GITHUB_OUTPUT"
    exit $TEST_RET
fi
