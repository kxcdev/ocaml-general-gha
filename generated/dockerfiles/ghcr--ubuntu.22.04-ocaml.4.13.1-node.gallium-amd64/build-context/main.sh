#!/bin/bash

## the context of the running GitHub Action workflow will be mounted at /github/workspace
## ref: https://github.com/orgs/community/discussions/26855

### STEP 0.
pushd /github/workspace

# print workspace and ci machine info
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


### STEP 2. build and test
echo && echo ">>> dune build and runtest"
(set -xe
 opam exec -- dune build
 opam exec -- dune runtest)
