# Agent Reach — shared research and discovery resource

**Status:** catalogued for selective use; not installed or embedded in the game runtime.  
**Upstream:** https://github.com/Panniantong/Agent-Reach  
**Upstream license:** MIT  
**Reviewed upstream HEAD:** `c70ae6da5d39bc90e09ad2ae0575ccc89f31e284` (2026-11-08)  
**Declared package version:** `1.6.1`; Python `>=3.10`; project maturity is Beta.

## Purpose

Agent Reach is a CLI/tooling layer that gives AI agents read/search access to multiple web and community sources through a unified interface. It is useful as a research assistant for discovering repositories, reading documentation, locating tutorials and collecting evidence. It is not a game engine, asset pack, animation system, or runtime dependency for Nova Ancient Warrior.

## Useful channels and project applications

| Channel | Potential use in our projects | Availability notes |
|---|---|---|
| GitHub | Discover and inspect game-engine plugins, code examples, issues and pull requests | Default channel |
| YouTube | Search tutorials and retrieve video captions/transcripts | Some transcription paths need a Groq or OpenAI key |
| Web | Search and read technical documentation | Default channel |
| Reddit | Community troubleshooting and developer experience | Optional; authentication may be required |
| Bilibili | Additional technical tutorials and captions | Default channel; some caption actions need login |
| X / Twitter | Track project updates and technical discussions | Experimental; login required |
| Xiaohongshu / LinkedIn / Instagram / Facebook | Optional research sources when genuinely relevant | Optional/experimental; login and anti-bot limitations apply |

## Recommended usage policy

1. Use Agent Reach for discovery and read-only research; do not treat search results as verified facts.
2. For any code or asset candidate, inspect the original upstream repository, exact commit, license, dependencies, maintenance status, and compatibility with our engine/toolchain.
3. For game assets, check the license of each asset separately. The Agent Reach MIT license does not change the licenses of content it discovers.
4. Never automatically copy code, install dependencies, import assets, or modify production projects from search results.
5. Keep it outside the Godot/Android runtime. Integrate only through a separate developer research environment or controlled CI job if later approved.
6. Do not put passwords, API keys, browser profiles, cookies, or session files in chat, repository files, CI logs, or artifacts. Use a dedicated low-privilege account for sites that require login.
7. Treat experimental channels as best-effort and expect breakage when upstream sites change.
8. Prefer public, no-login sources and free/open-source options. Record any paid service, key requirement, or rate limit before use.

## Safe evaluation and onboarding

The upstream install guide explicitly warns that the similarly named PyPI package is not this project. If installing, follow only the official GitHub release/install instructions:

- Install guide: https://github.com/Panniantong/Agent-Reach/blob/main/docs/install.md
- Releases: https://github.com/Panniantong/Agent-Reach/releases
- Security policy: https://github.com/Panniantong/Agent-Reach/blob/main/SECURITY.md

Upstream currently documents installation using `uv tool install` from its GitHub release ZIP, followed by `agent-reach setup`. Do not install the package by guessing a PyPI name. Before installation in any environment, inspect the current release, install guide, dependency constraints and security notes.

## Initial adoption decision

**Adopt as an optional research tool, not as a mandatory dependency.** First use should be a sandboxed evaluation on a developer workstation or disposable environment. Run its own status/diagnostics and tests, then compare a small set of findings against primary sources. Do not install it on Android or bundle it in the APK.

## Upstream references

- Repository: https://github.com/Panniantong/Agent-Reach
- README: https://github.com/Panniantong/Agent-Reach/blob/main/README.md
- Install/update guide: https://github.com/Panniantong/Agent-Reach/blob/main/docs/install.md
- Changelog: https://github.com/Panniantong/Agent-Reach/blob/main/CHANGELOG.md
- License: https://github.com/Panniantong/Agent-Reach/blob/main/LICENSE
