# VibeCheck 🤙

![VibeCheck Logo](./media/logo.png "VibeCheck Logo")

![Vibe](https://img.shields.io/badge/Vibe-Immaculate-ff00d4?style=for-the-badge) ![Zig](https://img.shields.io/badge/Made%20With-Zig-orange?style=for-the-badge&logo=zig) ![VibeCheck](https://img.shields.io/badge/Vibes-Checked-blue?style=for-the-badge) ![Size](https://img.shields.io/badge/Size-105KB-brightgreen?style=for-the-badge)

> "Yes, I even vibe checked vibe check 🤯"

**VibeCheck** is a high-performance **Zig** CLI tool that scans your codebase for "unfinished vibes"—To-Dos, hardcoded secrets, debug prints, and other signs of developer desperation.

It's fast, configurable, and CI/CD ready.

## Features

- **⚡ Blazing Fast**: Recursively scans thousands of files in milliseconds.
- **🪶 Featherweight**: ~105KB static binary. Zero dependencies. Runs on a potato 🥔 🎤
- **📦 Portable**: Single executable. Linux, Mac, Windows. No `node_modules` in sight.
- **🛡️ Battle Tested**: Validated against a 50,000-file "Google-scale" monorepo.
- **🧩 Modular**: Load custom pattern packs via JSON plugin system.
- **🤖 CI/CD Native**: 
  - Non-zero exit codes for build failures.
  - JSON output for machine parsing.
  - GitHub Actions Annotations support (`--github`).

## Installation

### Build from Source

Requirements: [Zig 0.13+](https://ziglang.org/download/)

```bash
git clone https://github.com/your-org/vibecheck.git
cd vibecheck
zig build -Doptimize=ReleaseSmall
```

The binary will be in `zig-out/bin/vibecheck`.

## Usage

**Basic Scan** (Human Readable)
```bash
vibecheck .
```

**CI/CD Mode** (Machine Readable + Exit Codes)
```bash
vibecheck . --json
```

**GitHub Actions Mode** (PR Annotations)
```bash
vibecheck . --github
```

**List Active Patterns**
```bash
vibecheck list-patterns
```

## Configuration (`vibecheck.toml`)

Configure ignores, thresholds, and external packs.

```toml
[scan]
max_results = 100
ignore = ["*.tmp", "node_modules/", "vendor/"]
# Calculate your own vibes:
# packs = ["./my-custom-vibes.json"]

[output]
# Fail the build on 'error', 'warn', or 'info'
fail_on = "error"
```

## Vibe Packs

VibeCheck comes with **Crucial Vibes** built-in:
- **Mock Data**: `lorem` `ipsum`, `John` `Doe`
- **Fragile Paths**: `localhost` `:3000`, `127` `.0.0.1`
- **Security Laziness**: `verify` `=False`, `chmod` `777`
- **Desperation**: `FIX` `ME`, `X` `X` `X`

You can extend this by creating your own JSON packs (see `extra_vibes.json` in `examples/`).

## License
MIT
