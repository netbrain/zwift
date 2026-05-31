---
title: Running Linters
parent: Development Environment
nav_order: 2
---

# Linters

## Running Linters Locally

### Run these before submitting a PR to catch issues early

#### Bash scripts

```console
foo@bar:~$ find . -path ./.git -prune -o -name "*.sh" -exec shellcheck {} +
foo@bar:~$ shfmt -d .
```

#### Dockerfile

```console
foo@bar:~$ hadolint src/Dockerfile
```

#### GitHub Actions

```console
foo@bar:~$ actionlint
```

#### Markdown

```console
foo@bar:~$ markdownlint-cli2
foo@bar:~$ cspell
```

#### Nix files

```console
foo@bar:~$ nil diagnostics -- *.nix
foo@bar:~$ nixfmt --check -- *.nix
```

#### YAML

```console
foo@bar:~$ yamllint .
```
