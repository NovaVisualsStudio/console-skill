# Curated Engineering Skills & Toolchain

Reviewed: 2026-11-08

This is a curated reference and decision policy for future work across games, mobile apps, web apps, backend services, graphics, QA, and release engineering. Listing a resource does **not** mean it has been installed, executed, or integrated. Keep the current project architecture unless a measured technical reason justifies a change.

## 1. Recommended skill sources

| Priority | Resource | Best use | License / caution | Decision |
|---|---|---|---|---|
| A | [Skyrant/gamedev-agent-skills](https://github.com/Skyrant/gamedev-agent-skills) | Engine-routed game skills: Godot, art pipeline, AI, procedural generation, dialogue, saves, audio, shaders, physics, level design, input, UI/UX, camera, performance | Apache-2.0 repository license; verify any third-party assets separately | Primary game-development skill reference |
| A | [Game Dev Studio](https://github.com/toilanguyen2910/game-dev-studio) | Production workflow, specialist roles, GDD/ADR/UX templates, planning and QA gates | MIT | Use for production process and templates, not as a replacement game project |
| A | [awesome-mobile-agent-skills](https://github.com/almasumdev/awesome-mobile-agent-skills) | Stack-neutral mobile architecture, lifecycle, offline-first, testing, release and operations across Android/iOS/Flutter/React Native/KMP | Verify current repository license and per-skill provenance before copying | Primary cross-platform mobile reference |
| A | [thienqo/flutter-skills](https://github.com/thienqo/flutter-skills) | Flutter/Dart architecture, UI, networking, persistence, authentication, testing, security, performance, localization and CI/CD | BSD-3-Clause | Preferred Flutter-specific reference |
| B | [zakariaf/Flutter-Skills](https://github.com/zakariaf/Flutter-Skills) | Flutter architecture, Riverpod, tests, persistence, RTL/i18n, accessibility, performance and release | MIT | Alternative Flutter reference; avoid duplicating overlapping guidance |
| B | [Game Dev Agentic Skills](https://github.com/thedivergentai/Game-Dev-Agentic-Skills) | Godot 4.7+ / Bevy domain skills, evidence-led project analysis and engine-specific workflows | LGPL-3.0; review obligations before copying or redistributing modified covered files | Specialist reference; use selectively |
| B | [EL4CTEO/blender-skills](https://github.com/EL4CTEO/blender-skills) | Blender modeling, materials, rigging and asset pipeline guidance | Inspect current upstream license and each asset | Art pipeline reference |
| B | [jammyfu/open-game-skills](https://github.com/jammyfu/open-game-skills) | Broad game-production practices | Inspect current upstream license and individual skill provenance | Secondary reference |
| B | [majidmanzarpour/blender-game-skills](https://github.com/majidmanzarpour/blender-game-skills) | Blender/game asset workflows | Inspect current upstream license and individual skill provenance | Secondary reference |
| C | [SummerEngine 3D Open World TPS template](https://github.com/SummerEngine/template-3d-open-world-explore-tps) | Study third-person movement, orbit camera, terrain, NPC interaction, quest and HUD patterns | Code is MIT; third-party assets retain their own licenses; Summer Engine compatibility must be checked | Read patterns only; do not replace Nova's scenes |
| C | [LeanEntropy Godot 3D base template](https://github.com/LeanEntropy/Godot_3D_base_template) | Compare generic 3D controller/camera patterns | Targets Godot 4.4, older than this project's 4.7 feature declaration | Do not import without porting and regression tests |

## 2. Selected software by project type

### 3D action games (Nova Ancient Warrior)
- **Engine:** Godot 4.7, keep the existing project. Use GDScript for gameplay unless profiling or a concrete integration requires C#.
- **3D content:** Blender for modeling, retopology, UVs, rigging, animation and export; use a reproducible GLB/glTF import pipeline.
- **Textures/materials:** Krita or GIMP for 2D authoring; Material Maker or procedural Godot shaders where they improve iteration. Check licenses and runtime cost for every asset.
- **UI/design:** Figma for interface exploration and design tokens; implement and validate the final UI in Godot.
- **QA/performance:** Godot headless tests + GitHub Actions for repeatable checks; Godot profiler and Android GPU/system profiling on real target devices before tuning claims.
- **Android renderer policy:** maintain a tested compatibility renderer baseline; evaluate Forward+/Mobile renderer per target GPU rather than assuming the highest renderer is fastest. Keep scalable MID/HIGH presets and measure frame time, memory, thermal behavior and loading.

### Android applications
- **Android-only native product:** Kotlin + Jetpack Compose + Android Studio is the default choice for deep Android APIs, platform fidelity and native performance.
- **Android + iOS from one codebase:** Flutter + Dart is the default choice for a polished shared UI and consistent cross-platform delivery.
- **React Native:** choose when the product is strongly TypeScript/React-oriented or shares substantial web logic; validate native-module needs and performance early.
- Do not mix Flutter, React Native and native UI in one app without a clear product or technical reason.

### Web applications and SaaS
- **Frontend:** TypeScript + React/Next.js for full web products; use a smaller Vite + React app when server rendering and SEO are unnecessary.
- **Backend:** choose a typed API service and PostgreSQL for relational data; use Supabase when managed Postgres, authentication and storage accelerate delivery. Use Firebase when realtime/mobile SDK integration is the central requirement.
- **Testing:** Playwright for browser-level end-to-end checks; unit/integration tests at service and component boundaries.
- **Operations:** Sentry or equivalent error monitoring, structured logs, metrics and alerting. Never ship secrets in client code.

### Shared visual/design pipeline
- **Figma:** layout systems, reusable components, typography, spacing, responsive states and design handoff.
- **Blender:** game-ready 3D assets and animation.
- **Krita/GIMP:** texture, sprite, icon and image editing.
- Keep generated assets under source control with provenance, dimensions, format, license, import settings and target budget recorded.

## 3. Quality gates required for every serious project

1. Requirements and architecture: concise specification, acceptance criteria, dependency map and decision records.
2. Code quality: formatter, static analysis/lint, type checks where available, dependency/license review and secret scanning.
3. Automated tests: unit + integration + end-to-end tests appropriate to the stack; deterministic fixtures and reproducible CI.
4. Security: threat review, OWASP guidance relevant to web/mobile, secure secret storage, authorization checks and dependency vulnerability scanning.
5. Performance: profile first; set budgets for CPU/GPU frame time, memory, startup, network, bundle size and battery/thermal behavior.
6. Device/browser matrix: test supported Android tiers, screen sizes, OS versions and browser engines; CI is not a substitute for physical-device testing.
7. Release: signed production artifacts, versioning, crash reporting, rollback plan, privacy disclosures and store-policy validation.
8. Evidence: every claim must name the exact commit, workflow, device/emulator, test scope and remaining limitations.

## 4. Nova Ancient Warrior adoption plan

1. Keep Godot 4.7 and the current project structure; do not replace the game with an unrelated starter template.
2. Use the Skyrant skill router as the main game reference. Select only Godot + 3D + performance + AI + combat + camera + animation + UI + save + audio + QA skills for the task at hand.
3. Use Game Dev Studio templates for GDD, technical decisions, task breakdown and QA sign-off.
4. Use Blender skills for original hero/enemy/environment asset production, subject to license, runtime and export checks.
5. Treat external starter templates as pattern libraries. Port one small subsystem at a time and compare behavior with the existing project.
6. Keep changes on the dedicated integration branch. Never overwrite main or merge the open development PR without explicit approval.
7. Before accepting a performance improvement, compare baseline and candidate builds with the same scenes, device class, resolution and measurement procedure.

## 5. Current limits and non-claims

- These links and recommendations are curated references, not proof that the external skills have been installed into an agent runtime.
- GitHub documentation does not execute Blender, Godot Editor, Android Studio, Flutter or a device farm by itself.
- No physical Android device benchmark is claimed by this document.
- Do not import third-party art until its exact license, attribution, source and technical compatibility are verified.
- The project's current Godot version declaration is 4.7. Keep compatibility checks aligned with it.

## 6. Newly discovered specialist skills (2026-11-08)

These are additional upstream skill libraries discovered and inspected after the initial shortlist. Prefer loading only the specialist skill needed for a task.

| Priority | New source | Specialist skills worth consulting | License / integration decision |
|---|---|---|---|
| A | [edemaistre/godot-expert-skills](https://github.com/edemaistre/godot-expert-skills) | `godot-3d-world`, `godot-animation`, `godot-gameplay`, `godot-rendering-lighting`, `godot-shaders`, `godot-vfx`, `godot-audio`, `godot-pipeline-automation`, `godot-performance-export` | README and individual skills inspected; repository license file was not located during this review. Use as read-only technical reference only until explicit licensing is confirmed; do not copy files into the project yet. |
| A | [oh-ashen-one/blender-agent-skills](https://github.com/oh-ashen-one/blender-agent-skills) | `blender-staged-scene-construction`, `concept-target-visual-gate`, plus isolated Blender sessions | MIT license verified. Suitable for staged procedural environment production, reproducible GLB export, visual comparison against fixed references and honest screenshot-based acceptance. Preserve MIT notice if any skill text is copied. |
| B | [bgrenat/godot-game-dev-studio](https://github.com/bgrenat/godot-game-dev-studio) | `studio-router`, `studio-godot-technical-director`, `studio-gameplay-lead`, `studio-level-design-lead`, `studio-qa-playtest-lead`, `studio-performance-release-lead` | 189 skills advertised in the inspected README; LGPL-3.0 distribution with third-party provenance in NOTICE. Large aggregator overlaps existing sources; use its catalog/router selectively and do not bulk-copy or install the whole package into Nova. |

### Immediate task routing for Nova Ancient Warrior

- **3D levels and world dressing:** consult `godot-3d-world`; focus on terrain, collision, LOD, instancing, GLB import and camera collision. Adapt only after checking the current project's renderer and scene structure.
- **Hero/enemy animation:** consult `godot-animation`; audit retargeting, AnimationTree transitions, root motion, foot sliding, hit reactions and upper-body layers. Do not replace the current character or animation assets blindly.
- **Enemy combat and navigation:** consult `godot-gameplay`; review state machines, NavigationAgent3D, hitbox/hurtbox contracts, telegraphs, save/load and deterministic headless tests.
- **Visual fidelity and environments:** use Blender staged construction plus the concept-target visual gate. Each milestone must be backed by an actual render or in-engine screenshot; concept art is not proof of a finished asset.
- **Mobile performance:** consult `godot-performance-export`; classify CPU vs GPU bottlenecks, measure frame time and memory, check shader-compilation/loading hitches, and test sustained sessions on real Android target devices. Do not transplant desktop benchmark numbers to phones.
- **Production and QA:** use the Game Dev Studio router/QA/release roles as checklists, not as authority to change the engine or overwrite project architecture.

### Future project routing

- For future Godot games, reuse the Godot specialist skills selectively and keep project-specific architecture, controls, rendering and asset budgets separate.
- For Blender-heavy asset production, use the MIT Blender workflow skills as a repeatable art pipeline.
- For future apps, continue using the previously curated native Android (Kotlin/Compose), Flutter and web stacks according to platform needs; game-engine skills are not substitutes for mobile-app architecture, privacy/security review or app-store release checks.

### Verification boundary

Repository metadata and selected README/SKILL.md files were inspected on 2026-11-08. This does not mean the skills have been installed into the current assistant runtime, executed against Nova, or validated on a physical Android phone. The Godot Expert Skills procedures report testing on Godot 4.7.2 on macOS; treat that as upstream evidence, not a Nova/Android benchmark. The Blender skills are workflow instructions, not Blender execution in this environment.
