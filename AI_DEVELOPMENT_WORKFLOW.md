# Reusable AI-assisted development workflow

This workflow is intended for Nova Ancient Warrior and future software/game projects in this repository.

## Roles
- **ChatGPT / project lead:** clarify requirements, research current documentation and licenses, break work into verifiable tasks, coordinate reviews, and report evidence.
- **Codex:** primary implementation agent for code changes, refactoring, tests, and build/debug loops.
- **Claude Code:** independent reviewer and secondary implementation agent for isolated tasks; avoid having two agents edit the same files concurrently.
- **GitHub Actions:** reproducible CI gate for formatting, static checks, unit tests, engine validation, and build artifacts.

## Safe sequence
1. Create a task branch from the agreed base.
2. Write acceptance criteria and a test plan before implementation.
3. Assign one agent as the owner of a change. Other agents review the diff, not edit the same working tree.
4. Run local checks, then GitHub Actions.
5. Fix failures and rerun the affected checks.
6. Open or update a pull request with a summary, tests, screenshots/logs where useful, and known limitations.
7. Human reviews and explicitly approves merge/release.

## Review gates
- **Correctness:** requirements, edge cases, state transitions, error paths.
- **Security:** secrets, permissions, untrusted downloads, injection, unsafe deserialization.
- **Quality:** architecture, readability, maintainability, accessibility/usability.
- **Performance:** CPU, GPU, memory, network, storage, startup, mobile constraints.
- **Supply chain:** dependency pinning, maintenance, provenance, exact asset licenses.
- **Evidence:** test output, build status, device/emulator results, reproducible steps.

## Project portability
For a new repository, copy `AGENTS.md`, `CLAUDE.md`, and this workflow file, then replace the project-specific section in `AGENTS.md` with the new engine/runtime, supported platforms, test commands, and release constraints.

## Credentials and external services
Never place credentials in source files, issues, chat messages, or logs. Store them only in the relevant service's secret manager and grant the minimum required permissions. Paid APIs and services must remain disabled until the project owner explicitly authorizes their use.
