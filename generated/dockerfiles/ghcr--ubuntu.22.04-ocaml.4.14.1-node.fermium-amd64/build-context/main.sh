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
    bash -xe -c "$OGA_SETUP_COMMAND"
fi

### STEP 2. build
echo && echo ">>> build project"
if [ -z "$OGA_BUILD_COMMAND" ]; then
    (set -xe
     opam exec -- dune build)
else
    (set -xe
     opam exec -- bash -c "$OGA_BUILD_COMMAND")
fi

### STEP 3. test
if [ "$OGA_SKIP_TESTING" == "true" ]; then
    echo && echo ">>> testing is skipped as inputs.skip-testing is set"
else
    echo && echo ">>> test project"
    if [ -z "$OGA_TEST_COMMAND" ]; then
        (set -xe
         opam exec -- dune runtest)
    else
        (set -xe
         opam exec -- bash -c "$OGA_TEST_COMMAND")
    fi
fi
