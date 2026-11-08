# Nova Ancient Warrior - External Research Repository Catalog

Reviewed on: 2026-11-08
Project branch: nova-full-campaign-polish

This catalog connects the project to six external repositories supplied for research. These repositories are reference sources, not trusted dependencies. The source-audit script checks repository availability, default branch heads, archive status and GitHub license metadata. It does not clone, execute, vendor or automatically merge third-party code.

## Recommended use order

### 1. Adventure Mode for Godot

Repository: https://github.com/EasterEggProductions/adventure-mode-godot
Reviewed revision: https://github.com/EasterEggProductions/adventure-mode-godot/commit/57d337f425af3b679de6c14eacc312872d07d007

Why it is useful:
- Godot 4.7 third-person project with locomotion and traversal patterns.
- Modular movement packages for walking, climbing and combat.
- Camera follow and look logic, actor and armament abstractions, action areas, collectibles and AI-related folders.
- Best candidate in this list for targeted study of traversal and modular movement.

Reviewed code licensing:
- LICENSE.txt explicitly applies MIT to software code.
- LICENSE.txt applies CC BY 4.0 to other assets.
- Code can be adapted with the MIT copyright and license notice retained.
- Any reused artwork, models, animations, music or sound requires CC BY 4.0 attribution and asset-level review.
- The repository states that machine-learning-generated contributions are not accepted into its upstream project. That is an upstream contribution rule; it does not remove the separate license obligations for code or assets used in Nova.

Candidate files to inspect:
- `Modular Mobility/MovementPackage.gd`
- `Modular Mobility/mvpk_walk.gd`
- `Modular Mobility/mvpk_climb.gd`
- `Modular Mobility/mvpk_combat.gd`
- `scripts/camera_control.gd`
- `scripts/actor.gd` and `scripts/armament.gd`

Integration cautions:
- These scripts depend on the source project's Actor class, AnimationTree layout, action names, root-motion assumptions and project-wide managers. They are not drop-in replacements for Nova's controller.
- Port only a small, isolated algorithm or subsystem. Add an attribution entry, adapt it to Nova's typed APIs, and run Android plus regression tests.

### 2. GOAT - Godot Open Adventure Template

Repository: https://github.com/miskatonicstudio/goat
Reviewed revision: https://github.com/miskatonicstudio/goat/commit/6c0d0905f8ff3eab06f6dff9a185544d5eef4c44

Why it is useful:
- Inventory data and item selection.
- Object interaction signals and interaction points.
- Dialogue playback, voice/subtitle orchestration and response handling.
- Settings persistence, localization and simple world-state variables.
- Useful as a source of patterns for future quests, objects, dialogue and settings systems.

Reviewed code licensing:
- Repository declares MIT.
- Keep its MIT copyright and license notice if code is copied or adapted.
- GOAT includes third-party dependencies and demo content with separate terms. Its README identifies some demo models as CC0 and other models as CC BY-NC 4.0. Do not copy demo media into Nova without checking each asset.
- Dialogue Manager and Random Audio Stream Player are separately licensed MIT projects and should be attributed separately if their code is reused.

Candidate files to inspect:
- `addons/goat/globals/goat_inventory.gd`
- `addons/goat/globals/goat_interaction.gd`
- `addons/goat/globals/goat_voice.gd`
- `addons/goat/globals/goat_settings.gd`
- `addons/goat/globals/goat_state.gd`

Integration cautions:
- The repository README warns that GOAT has been changing during its Godot 4/plugin migration and documentation may be outdated.
- The checked project.godot identifies Godot 4.3, whereas Nova uses Godot 4.7.2. Treat all code as a candidate for review, not a guaranteed compatible plugin.
- Avoid duplicating Nova's SaveManager, combat inventory or existing input systems. Extract only missing functionality.

### 3. Fly Dangerous

Repository: https://github.com/jukibom/FlyDangerous
Reviewed revision: https://github.com/jukibom/FlyDangerous/commit/2a520e98256187070ff58e84e819d3b791b47797

Why it is useful:
- A mature Unity/C# game with procedural terrain, input integration, replay/ghost, telemetry, multiplayer and game options.
- Useful for architectural study of telemetry, input abstraction, procedural world generation and profiling workflows.
- Low direct gameplay relevance to Nova's third-person melee adventure.

License and dependency restrictions:
- Code is GPL-3.0. Copying or adapting code into a distributed derivative requires GPL compliance; do not mix it into a closed/proprietary distribution without an explicit legal and architecture review.
- Project-owned models, textures and materials are CC BY-NC-SA 4.0 according to the README. These are not suitable for commercial use.
- The README also lists paid Unity Asset Store dependencies for the full release build and separate third-party licenses.
- Do not copy its art, branding, paid dependencies or source code into Nova in this pass. Use it for architecture and ideas only unless the distribution and license obligations are deliberately accepted.

### 4. CLUTCH

Repository: https://github.com/siddharth4001/CLUTCH
Reviewed revision: https://github.com/siddharth4001/CLUTCH/commit/04a307a603da78f9e943ed8bb462fee7d19bd07b

Why it is listed:
- A small Unity 2020.3.8 C# car-racing project.
- May provide a basic reference for vehicle input, wheel physics or collision handling if a vehicle feature is ever added.

License status:
- GitHub API reports no recognized repository license.
- The root contains a README but no LICENSE file was found in the inspected listing.
- No code, assets or scripts may be copied into Nova without written permission or a license supplied by the owner. Treat it as inspiration-only.

### 5. Lee Reilly - Games on GitHub

Repository: https://github.com/leereilly/games
Reviewed revision: https://github.com/leereilly/games/commit/c67976ddcf6f7aef26dc3884116205ab9ef40f74

Use:
- Large discovery index for games, engines, add-ons and utilities across platforms.
- It is archived and read-only. It is not itself a code library or blanket license for any linked project.
- Open each destination repository and verify its maintenance state, license and asset provenance before use.

### 6. Kavex - GameDev Resources

Repository: https://github.com/Kavex/GameDev-Resources
Reviewed revision: https://github.com/Kavex/GameDev-Resources/commit/f7c89aae1128fe1ab5f5acaec4c1ab76ee87c7c3

Use:
- Discovery catalogue for 2D/3D assets, engines, source projects, animation, audio, tools and learning resources.
- Its README itself recommends checking each resource's license.
- Labels such as free, limited-free or open-source are discovery hints only. They are not proof that a specific asset is suitable for commercial use.

## Integration policy for Nova

1. Keep Nova's existing Godot architecture as the source of truth.
2. Search this catalog before implementing a subsystem from scratch.
3. Prefer MIT, BSD, Apache-2.0 and CC0 code/assets where appropriate, while retaining notices and attribution.
4. Review code and asset licenses separately. A repository can have MIT code and non-commercial demo media.
5. Do not copy code from a repository with no license. Do not bring GPL code into a non-GPL distribution without an explicit decision.
6. Do not merge an entire project or blindly copy large folders. Review individual files, dependencies, engine version, input map, autoloads, node paths, animation names, Android compatibility and performance.
7. Preserve Nova's SaveManager and combat rules unless a tested migration plan explicitly replaces them.
8. For every reused file, record source URL, original path, author, license, license version, changes and attribution in `nova-ancient-warrior/ASSET_PROVENANCE.csv` or a dedicated code provenance ledger.
9. Test in an isolated branch or fixture first. Run focused smoke tests, all Godot regression checks, Android export and physical-device tests when the change affects runtime behaviour.
10. Never claim a dependency was integrated merely because it appears in this catalog.

## Automated source audit

Run from the repository root:

```bash
python nova-ancient-warrior/tools/research/audit_github_sources.py \
  --output build/research/source-audit.json
```

The tool queries public GitHub repository metadata and default branch heads. It does not download source files, execute third-party code or decide legal compatibility. Review the human-readable license notes in this document before reuse.

A GitHub Actions workflow can run the same audit manually and publish the JSON report as a workflow artifact.
