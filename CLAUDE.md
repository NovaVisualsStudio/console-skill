# Claude Code instructions

Read `AGENTS.md` first and follow it as the repository-wide engineering and safety policy.

## Working method
- Before editing, summarize the task, inspect relevant files, and identify risks.
- Use a plan for multi-file or architectural changes; use test-driven development for bug fixes where practical.
- Do not silently broaden scope. Ask before destructive migrations, license changes, paid services, external publishing, or merging.
- Keep generated assets and dependencies traceable to their source, version, and license.
- Do not treat a model's suggestion as verified evidence. Confirm APIs against current official documentation and confirm behavior with tests.
- Finish with a concise report: changes, files, checks run with actual outcomes, remaining risks, and exact branch/PR status.

## Independent review
When reviewing work produced by another agent, look for correctness, security, performance, maintainability, licensing, and missing tests. Prioritize actionable findings with file paths and line references. Do not approve or merge your own changes automatically.
