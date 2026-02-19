---
title: Development Environment
parent: Contributing
nav_order: 1
---

# Development Environment

This project provides two options for setting up a development environment with
all the linting and development tools used in CI.

## Option 1: Nix Flakes (Recommended)

[Nix flakes](https://nixos.wiki/wiki/Flakes) provide a reproducible development
environment that works on any Linux distribution.

### Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled
- Optionally [direnv](https://direnv.net/) for automatic shell activation

#### Enabling Flakes

If you haven't enabled flakes, add this to `~/.config/nix/nix.conf`:

```ini
experimental-features = nix-command flakes
```

### Entering the Development Shell

```bash
# One-time use
nix develop

# Or with direnv (recommended)
direnv allow
```

### Available Tools

The development shell includes all tools used in CI:

| Tool                | Purpose                         |
|---------------------|---------------------------------|
| `shellcheck`        | Bash script linting             |
| `shfmt`             | Bash script formatting          |
| `nil`               | Nix language diagnostics        |
| `nixfmt`            | Nix code formatting             |
| `hadolint`          | Dockerfile linting              |
| `markdownlint-cli2` | Markdown linting                |
| `cspell`            | Spell checking                  |
| `actionlint`        | GitHub Actions workflow linting |
| `yamllint`          | YAML linting                    |
| `podman`            | Container runtime               |
| `gh`                | GitHub CLI                      |

## Option 2: VS Code Devcontainer

If you use VS Code and prefer containers over Nix, a
[devcontainer](https://containers.dev/) configuration is included.

### Requirements

- [VS Code](https://code.visualstudio.com/)
- [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- Docker or Podman

### Getting Started

1. Open the project in VS Code
2. When prompted, click "Reopen in Container"
3. Or use the command palette: `Dev Containers: Reopen in Container`

The devcontainer includes:

- Docker-in-docker for building images
- Nix with `nil` language server
- shellcheck and hadolint
- VS Code extensions for real-time linting feedback

## Running Linters Locally

Run these before submitting a PR to catch issues early:

```bash
# Bash scripts
find . -path ./.git -prune -o -name "*.sh" -exec shellcheck {} +
shfmt -d .

# Nix files
nil diagnostics -- *.nix
nixfmt --check -- *.nix

# Dockerfile
hadolint src/Dockerfile

# Markdown
markdownlint-cli2
cspell

# GitHub Actions
actionlint

# YAML
yamllint .
```

## Building the Documentation Locally

The documentation uses Jekyll with the just-the-docs theme.

```bash
cd docs
bundle install
bundle exec jekyll serve
```

Then open <http://localhost:4000> in your browser.

## Building the Container Image

```bash
cd src

# Build the image
podman build -t zwift:dev .

# Or use the build script
./build-image.sh
```

## Testing Changes

```bash
cd src

# Dry run to see what would be executed
DRYRUN=1 ./zwift.sh

# Run in foreground for debugging
ZWIFT_FG=1 ./zwift.sh

# Interactive mode (drops into container shell)
INTERACTIVE=1 ./zwift.sh
```
