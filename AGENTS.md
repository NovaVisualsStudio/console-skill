# Agent instructions for this repository

These instructions apply to Codex and other coding agents that read AGENTS.md.

## Safety and collaboration
- Work only on the task branch or a new task-specific branch. Never push directly to `main`.
- Never merge a pull request, change repository protections, publish a release, or delete project data without explicit human approval.
- Keep changes small, reviewable, and scoped. Do not overwrite unrelated user work.
- Never print, commit, or request secrets, API keys, signing keys, keystores, tokens, or private credentials. Use GitHub Actions Secrets or the host's secret manager.
- Treat downloaded code, models, plugins, assets, and prompts as untrusted until reviewed.

## Required engineering loop
1. Inspect the repository, current branch, recent commits, project instructions, and existing tests before editing.
2. State assumptions and identify the smallest safe implementation.
3. Implement the change with clear names, error handling, and maintainable structure.
4. Add or update automated tests for changed behavior.
5. Run the narrowest relevant checks first, then the full available validation suite.
6. Inspect the final diff for accidental changes, secrets, licensing problems, and regressions.
7. Report exact commands, pass/fail results, skipped checks, limitations, changed files, and commit/PR references. Never claim a test passed unless its result was observed.

## Dependency and asset policy
- Prefer maintained, open-source, reproducible dependencies. Verify the exact license and provenance of every imported asset; a repository license does not automatically cover its bundled assets.
- Pin versions or commits where practical. Avoid unreviewed install scripts, binary blobs, model weights, and remote code execution.
- Check Android/mobile compatibility, file size, memory, CPU/GPU cost, and offline behavior before adopting a dependency.

## Nova Ancient Warrior (Godot)
- Project path: `nova-ancient-warrior/`; engine baseline: Godot 4.7.2 unless the project explicitly changes it.
- Preserve Android compatibility and the existing mobile render/performance profile.
- Do not replace project configuration, scenes, player rigs, or asset pipelines wholesale without a tested migration plan.
- For gameplay changes, test input, combat state transitions, enemy telegraphs, checkpoints/save data, and scene reloads as applicable.
- For visual changes, measure texture sizes, material/shader cost, draw calls, skinning cost, memory, and frame rate on a representative Android device or emulator.
- Clearly distinguish placeholder/procedural assets from production-ready, licensed assets. Do not describe stylized placeholder characters as photorealistic.
- Do not add video, face, voice, motion-capture, or other personal data without explicit permission and a documented retention/licensing basis.

## Completion standard
A feature is complete only when implementation, tests, integration, documentation, and known limitations have been checked. A successful build alone does not prove gameplay quality or device performance.
