# Zero-cost AI-assisted development workflow

This workflow applies to Nova Ancient Warrior and future software/game projects in this repository. The default and required budget is zero.

## Roles and free-first tools
- ChatGPT: planning, technical research, task breakdown, coordination, and evidence-based review within available account limits.
- Local open-source tools: Godot, Blender, Python, Git, and local model inference where existing hardware supports it.
- GitHub Free: source control and CI within the included quotas.
- Open-weight models: local inference only; no metered hosted model APIs.
- Do not assume Codex Cloud, Claude Code, fal.ai generation, or any hosted AI API is free.

## Safe sequence
1. Create a task branch from the agreed base.
2. Write acceptance criteria and a test plan before implementation.
3. Assign one implementation owner. Other reviewers inspect the diff rather than edit the same working tree.
4. Run local checks first, then GitHub Actions within free quotas.
5. Fix failures and rerun affected checks.
6. Open or update a pull request with summary, tests, evidence, and limitations.
7. Human reviews and explicitly approves merge/release.

## Review gates
- Correctness: requirements, edge cases, state transitions, and error paths.
- Security: secrets, permissions, untrusted downloads, injection, and unsafe deserialization.
- Quality: architecture, readability, maintainability, and usability.
- Performance: CPU, GPU, memory, network, storage, startup, and mobile constraints.
- Supply chain: dependency pinning, maintenance, provenance, and exact asset licenses.
- Evidence: test output, build status, device/emulator results, and reproducible steps.

## Cost and credentials policy
- Never enable subscriptions, paid APIs, metered endpoints, paid assets, or paid CI runners.
- Replace paid dependencies with maintained free/open-source alternatives where technically suitable.
- If no safe free equivalent exists, disable or omit the feature and explain the limitation.
- Do not store credentials in source, chat, issues, or logs.
- Optional AI code review must run locally. CI must use deterministic tests and must not call external model APIs.
- Use GitHub Actions only within included free quotas; simplify or stop workflows before any overage.
- A free tier with expiring credits or automatic paid overage is not considered zero-cost unless billing/overage is disabled.

## Portability
Copy AGENTS.md, CLAUDE.md, ZERO_COST_POLICY.md, and this workflow file into new repositories, then update engine/runtime, platforms, and test commands.