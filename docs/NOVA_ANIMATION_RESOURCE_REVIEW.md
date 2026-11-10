# Nova Ancient Warrior — character and animation resource review

**Review date:** 2026-11-10  
**Target:** Godot 4.7.2, Android Compatibility renderer, original Nova hero  
**Decision:** research candidates only; no third-party asset has been imported into the game.

## Highest-priority candidate: Quaternius Universal Animation Library

- Source: https://quaternius.com/packs/universalanimationlibrary.html
- License stated by publisher: CC0; personal, educational and commercial use is permitted.
- Publisher describes 120+ animations on a universal humanoid rig, including eight-direction locomotion, combat, death, swimming, crawling and emotes.
- Published formats include FBX, GLB and Blend. The page says the exported versions are tested for Godot, Unity and Unreal.
- Why it matters: Nova currently generates a small ten-clip animation set on its own rig. This library could replace or extend placeholder locomotion and combat clips without paying for an animation pack.
- Integration gate: obtain the exact free-tier files from the publisher, retain the CC0/source record, inspect the skeleton hierarchy and rest pose, retarget in Blender/Godot, then test root motion, foot contact, weapon grip, attack timing and Android import size. Do not assume every animation in the pack is included in the free download.

## Secondary candidate: GDQuest Open 3D Mannequin

- Source: https://github.com/gdquest-demos/godot-3d-mannequin
- License split: code MIT; art assets CC-BY 4.0. Attribution: “GDQuest and contributors” with https://www.gdquest.com/.
- Useful reference: third-person camera rig, spring-arm collision handling, state-machine movement and character animation organization.
- Compatibility caution: repository documentation targets Godot 3.2+ and the repository's last push is old. Treat it as a reference/asset candidate, not a drop-in Godot 4.7 controller. Porting and compatibility checks are required.
- Decision: do not replace Nova's movement, combat, save or input systems with this controller. Inspect only the character asset and reusable camera ideas.

## Reference-only candidate: Godot official Third Person Shooter demo

- Source: https://github.com/godotengine/tps-demo
- README identifies the current master branch as compatible with current Godot 4.x.
- License split in LICENSE.md: code MIT; art and music CC-BY 3.0. The license file also notes that some Substance Painter materials were derived from GameTextures.com content.
- Useful reference: high-quality Godot scene setup, camera handling, lighting, environment and production structure.
- Compatibility caution: it is a shooter demo, not a melee action-RPG. Third-party material provenance means individual materials must be excluded unless their reuse rights are independently clear.
- Decision: use for technical study and cleanly licensed code patterns only; do not bulk-copy the project or assets.

## Integration checklist before accepting any external animation

1. Verify the exact download, publisher, license text and attribution file.
2. Record the asset filename, source URL, retrieval date and checksum in the project's provenance record.
3. Confirm humanoid bone mapping, rest pose, scale, forward axis and animation naming.
4. Retarget a small sample first: Idle, Walk, Run, Dodge, LightAttack, HeavyAttack, HitReact and Death.
5. Check foot sliding, root drift, hand-to-weapon alignment, shield grip, clipping and transition blending.
6. Run Godot import and animation smoke tests, then compare APK size and Android frame pacing.
7. Keep Nova's original generated hero as a fallback until the new asset passes all gates.

## Research-tool boundary

Agent Reach is catalogued separately as an optional research/discovery tool. Its discovery output is not a license grant and must not automatically download, execute or import third-party code or assets. The findings above were checked against the publishers' public repository/license pages and the Quaternius publisher page.
