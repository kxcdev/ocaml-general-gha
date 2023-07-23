# ocaml-general-gha
GitHub Action to help using ghcr.io/kxcinc/ocaml-general in GitHub Actions

## Get Started

Simply add the following as a step to your GitHub Action workflow file:
```yaml
- name: Build and test OCaml
  uses: kxcdev/ocaml-general-gha@v2
```

A template / sample repository is available: https://github.com/kxcdev/ocaml-general-gha-template
- full example of workflow definition: [.github/workflows/build-test.yml](https://github.com/kxcdev/ocaml-general-gha-template/blob/main/.github/workflows/build-test.yml)

## Options

| Option | Default | Comments |
|---|---|---|
| `build-command` | `dune build` |  |
| `test-command` | `dune runtest` |  you can skip testing with the `skip-testing` option |
| `setup-command` | <details><summary>(collapsed)</summary>`opam install . --yes --deps-only --with-test --verbose`</details> | you can skip setup with the `skip-setup` option |
| `skip-testing` | `false` | specify `true` to skip testing  |
| `skip-setup` | `false` |  specify `true` to skip setup |

### Example with options
```yaml
- name: Build and test OCaml
  uses: kxcdev/ocaml-general-gha@v2
  with:
    setup-command: "opam install --locked . -y --deps-only"
    build-command: "dune build @ci"
    skip-testing: true
```
