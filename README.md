# GitHub Action for `ocaml-general`
GitHub Action to help using [ghcr.io/kxcinc/ocaml-general](https://github.com/kxcinc/pubinfra.dockerfiles/pkgs/container/ocaml-general) in GitHub Actions workflows.

## Get Started

Simply add the following as a step to your GitHub Action workflow file:
```yaml
- name: Build and test OCaml
  uses: kxcdev/ocaml-general-gha@v3
```

A template / sample repository is available: https://github.com/kxcdev/ocaml-general-gha-template
- full example of workflow definition: [.github/workflows/build-test.yml](https://github.com/kxcdev/ocaml-general-gha-template/blob/main/.github/workflows/build-test.yml)
- another example which builds odoc documents and uploads the result to GitHub Pages: [.github/workflows/build-test.yml](https://github.com/kxcdev/ocaml-general-gha-template/blob/main/.github/workflows/odoc-github-pages.yml)

## Options and Outputs

#### Example usage with options
```yaml
- name: Build and test OCaml
  uses: kxcdev/ocaml-general-gha@v3
  with:
    ocaml-version: 4.14.1
    setup-command: "opam install --locked . -y --deps-only"
    build-command: "dune build @ci"
    skip-testing: true
```

#### Options on Versions
| Option | Default | Comments |
|---|---|---|
| `ocaml-version` | `5.0.0` | [see below for available values](#notes-on-versions) |
| `node-version` | `latest` | [see below for available values](#notes-on-versions) |

#### Options on Result Reporting
| Option | Default | Comments |
|---|---|---|
| `report-test-result` | `true` | specify `false` to disable reporting test result to GitHub GUI |
| `pr-report-test-result` | `true` | specify `false` to disable reporting test result to GitHub PR (effectively `false` when `report-test-result` is `false`) |

#### Options on Command Customization
| Option | Default | Comments |
|---|---|---|
| `build-command` | `dune build` |  |
| `test-command` | `dune runtest` |  you can skip testing with the `skip-testing` option |
| `setup-command` | <details><summary>(collapsed)</summary>`opam install . --yes --deps-only --with-test --verbose`</details> | you can skip setup with the `skip-setup` option |
| `skip-testing` | `false` | specify `true` to skip testing |
| `skip-setup` | `false` |  specify `true` to skip setup |

#### Options and Outputs on `odoc` and its GitHub Pages Integration
| Option | Default | Comments |
|---|---|---|
| `with-odoc` | `false` | specify `true` to enable odoc related features |
| `odoc-build-command` | <details><summary>(collapsed)</summary>`opam exec -- dune build @doc`</details> | set to override the default odoc build command |
| `odoc-upload-artifact` | `true` | whether upload odoc document site as a GitHub Actions artifact |
| `odoc-upload-artifact-name` | `github-pages` | artifact name when `odoc-upload-artifact` is set to `true` |
| ~`odoc-deploy-github-pages`~ | `false` | feature not yet available; specifying `true` will result the action to fail |

| Output | Available When | Comments |
|---|---|---|
| ~`odoc-site-path`~ | `with-odoc` is `true` | not available due to actions/runner#2009 |
| ~`odoc-github-pages-url`~ | `with-odoc` and `odoc-deploy-github-pages` are true | not available due to actions/runner#2009 |

### Notes on versions
- refer to the matrix of `build-deploy-ocaml-general` job at https://github.com/kxcinc/pubinfra.dockerfiles/blob/main/.github/workflows/ocaml-general.yml
  for the most up-to-date list of supported versions
  - snapshot at [5edf17ece403e6dc9e303bd69e023413b571a5ed](https://github.com/kxcinc/pubinfra.dockerfiles/blob/5edf17ece403e6dc9e303bd69e023413b571a5ed/.github/workflows/ocaml-general.yml#L93-L108):
    ```yaml
    ocaml-version:
      - 4.12.1
      - 4.13.1
      - 4.14.1
      - 5.0.0
    node-version:
      - fermium # v14 Maintenance LTS
      - gallium # v16 Active LTS
      - hydrogen # v18 Active LTS
      - latest
    ```

