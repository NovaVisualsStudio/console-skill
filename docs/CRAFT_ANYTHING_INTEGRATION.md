# Craft Anything integration (safe, opt-in workflow)

This guide adds a non-destructive workflow for using [Craft Anything](https://github.com/storytold/craft-anything) alongside the Console skills. It does **not** replace PS2Recomp, PCSX2, Ghidra, or any existing Console skill.

## Scope and compatibility

Craft Anything is an early-alpha, Rust-based inspection/build engine with CLI and MCP tools. Use it as a secondary inspection and project-validation assistant for separately prepared builds, application packages, archives, crash dumps, and supported game asset formats.

It is **not** a PS2 emulator, a PS2 static recompiler, or a replacement for PS2Recomp. Keep the existing PS2 pipeline and game-specific tools as the source of truth.

## Safe setup

1. Install Craft Anything on a supported desktop environment using the official instructions/releases in its upstream repository.
2. Install and authenticate your chosen local coding agent independently (for example Claude Code, Codex, or another supported ACP agent). Craft Anything does not provide or transfer agent credentials.
3. Open a **copy** of the relevant project or a separately exported build. Never point an agent at an irreplaceable original.
4. Start in **Clean room** mode. Use Deep mode only for software you own or are authorized to inspect, and only when reading its files/code is permitted.
5. Keep approvals for writes, shell commands, publishing, deletion, and system changes set to ask/refuse unless the task clearly requires otherwise.
6. Save evidence reports and unresolved questions alongside the working copy; review changes before copying accepted fixes back.

Example CLI discovery after installing the upstream app and CLI:

```sh
craft-anything-cli commands
craft-anything-cli --help
```

Exact command arguments depend on the installed release and target type. Consult the upstream generated tools reference before invoking individual tools. Configure the local agent using the current upstream MCP instructions rather than copying stale configuration.

## Suggested Console workflow

1. `/console-reverse` remains the primary skill for mapping a PS2 title you own and setting up the PS2Recomp project.
2. Use Craft Anything's archive/format inspection only on lawful, locally held inputs and isolated copies. Do not upload game ISOs, BIOS files, copyrighted game assets, or extracted proprietary content to GitHub or cloud services.
3. Use `/console-backend`, `/console-graphics`, `/console-sound`, `/console-physics`, and `/console-tester` for their existing specialized tasks.
4. Use Craft Anything as an additional evidence/checking pass on the resulting separate build where its supported tools apply.
5. Let `/console-tester` and the actual target runtime decide whether a port boots and plays correctly. A clean Craft Anything report alone is not proof.

## Android and device limits

Craft Anything's desktop app/CLI requires a supported host environment; this guide does not claim it runs directly on an Android phone. Android APK inspection tools are not the same as running the full desktop app on Android. For phone-only workflows, use a remote supported computer if available, and transfer only authorized project files.

## Repository protection rules

- Work on a feature branch; do not write directly to `main`.
- Keep original disc images, BIOS, proprietary assets, credentials, and private dumps out of Git.
- Do not auto-merge generated changes. Review diffs, run repository tests, and request approval before merging.
- Record tool versions, commands, evidence, and limitations so results can be reproduced.

## Upstream references

- [Craft Anything source](https://github.com/storytold/craft-anything)
- [Generated tool reference](https://github.com/storytold/craft-anything/blob/main/docs/tools.md)
- [Upstream status and verification notes](https://github.com/storytold/craft-anything/blob/main/docs/STATUS.md)
- [Using Claude Code as the builder](https://github.com/storytold/craft-anything/blob/main/docs/claude-code.md)
