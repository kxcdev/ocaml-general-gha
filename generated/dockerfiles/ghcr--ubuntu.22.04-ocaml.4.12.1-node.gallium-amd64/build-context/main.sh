#!/bin/bash

## the context of the running GitHub Action workflow will be mounted at /github/workspace
## ref: https://github.com/orgs/community/discussions/26855

### STEP 0.
pushd /github/workspace

# print workspace and ci machine info
echo ">>> DEBUG INFO"
echo OGA_BUILD_COMMAND: "$OGA_BUILD_COMMAND"
echo OGA_TEST_COMMAND: "$OGA_TEST_COMMAND"
echo OGA_SKIP_TESTING: "$OGA_SKIP_TESTING"

echo ">>> GITHUB_WORKSPACE"
echo "$GITHUB_WORKSPACE"

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
echo && echo ">>> install OCaml dependencies"
(set -xe; opam install . --yes --deps-only --with-test --verbose)


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
         opam exec -- dune build)
    else
        (set -xe
         opam exec -- bash -c "$OGA_TEST_COMMAND")
    fi
fi
