# GitLab Game-Development Skills Review — Nova Ancient Warrior

Review date: 2026-11-08  
Project target: Godot 4.7, 3D third-person sword action, Android ARM64  
Decision: adopt one GitLab skill as a design/research advisor; do not replace the existing Godot engineering and art pipelines.

## Best verified GitLab candidate

### Shawn Benson — game-development
Repository: https://gitlab.com/shawn-benson/game-development  
Skill directory: `skills/game-development/`  
Latest observed commit: `d74c3742` (short SHA as displayed by GitLab during this review)  
License: MIT, as stated in the repository README.  
Format: portable Agent Skills `SKILL.md`.

This was the strongest directly relevant GitLab skill found in the public GitLab search results. The repository describes a game-development advisor for design, diagnosis and implementation, grounded in a source registry of 355 entries: 206 GDC Vault talks, 86 peer-reviewed papers, 21 books and 42 official engine/platform documents. It reports claim-level citation review and provides reference modules for game feel, levels, narrative, systems, AI, procedural generation, architecture, presentation, accessibility, evaluation and production.

The repository also publishes agent behavior evaluations. Those are maintainer-reported results, not an independent benchmark of this project or proof that the skill improves every model. Treat them as useful evidence of tested routing and source attribution, not a guarantee of better game output.

## Why it is selected

It fills a gap not fully covered by code-centric Godot skills: design reasoning and evidence-backed diagnosis. Use it before implementing consequential changes to:
- Sword-combat feel: input buffering, responsiveness, hit feedback, camera, animation timing and readable enemy telegraphs.
- Enemy and boss design: behavior patterns, difficulty curves, phase readability and counterplay.
- Level structure: onboarding, navigation, pacing, landmarks, encounter placement and exploration loops.
- Narrative and presentation: dialogue, quests, audio, accessibility and visual communication.
- Production decisions: scope control, playtest design, evidence collection and deciding whether a feature is actually improving the experience.

## Integration boundary

This skill is complementary, not a replacement:
- Godot 4.7 implementation, GDScript APIs, scene/resource changes and runtime debugging remain governed by Godot-specific skills and official Godot 4.7 documentation.
- Blender modeling, retopology, PBR, rigging, animation and export remain governed by Blender-specific skills and validated production tools.
- Android performance claims require measurements from actual exported builds on physical devices.
- Do not copy cited GDC talks, papers, book text or third-party material into the game. Use the skill's original summaries and source links, and observe each source's rights.

## Safe adoption procedure

1. Keep this GitLab project as a pinned external reference until its full `SKILL.md`, reference files, helper scripts, tests and license are reviewed from the upstream repository.
2. Before vendoring, resolve the full immutable commit SHA from GitLab and record per-file provenance.
3. Audit helper scripts before execution. Do not run installers or scripts with broad filesystem/network access in a privileged environment.
4. Import only the skill folder and references required for the game; do not import the deprecated historical MCP server or unrelated tooling.
5. Add a project-local routing note only after the actual skill files are present and their paths have been verified.
6. Run the source repository's own tests where possible, then evaluate it on Nova-specific design cases with and without the skill. Record rubric scores and failure examples.

## Review finding: GitLab search coverage

The public GitLab search surfaced this directly relevant AI game-development skill and GitLab topic pages containing game projects/assets. It did not establish a second GitLab skill pack with stronger Godot 4.7 + 3D combat + Blender + Android coverage. Do not pad the shortlist with ordinary game repositories, asset dumps, unrelated anti-cheat projects or unverified mirrors and call them agent skills.

## Recommended use in this project

Route tasks in this order:
1. Game-development advisor (GitLab): define the player experience, diagnosis, design alternatives and evidence.
2. Godot 4.7 engineering skills: implement the approved system and add tests.
3. Blender/technical-art skills: produce and validate character, animation, environment and material assets.
4. QA/performance skills: run regression checks and capture physical-device performance evidence.
5. Human review: inspect visual output, combat feel, accessibility, licensing and release readiness.

## Sources

- https://gitlab.com/shawn-benson/game-development
- https://gitlab.com/explore/projects/topics/game-development
- https://gitlab.com/explore/projects/topics/game-assets
- https://docs.godotengine.org/en/4.7/tutorials/performance/index.html

