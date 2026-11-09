# NOVA — Third-party credits and asset provenance

## Character generation pipeline

- **Ara 3D Gen** — https://github.com/olatunde85/3d-gen  
  Generator source is MIT-licensed. NOVA uses it as a build-time character-generation tool; the application does not bundle Ara's web application or runtime code.
- **MakeHuman character data** — https://www.makehumancommunity.org/  
  The core character data used by Ara (base mesh, morph targets, rig, skin textures, hair and clothing assets) is released under CC0 1.0 according to the source project's asset license. Verify the current per-asset notice before replacing or adding any third-party asset.
- **CMU Graphics Lab Motion Capture Database** — http://mocap.cs.cmu.edu/  
  Motion clips retargeted by Ara may be used in commercial products but may not be resold directly as motion data, including converted forms. Required acknowledgement:

  > The data used in this project was obtained from mocap.cs.cmu.edu. The database was created with funding from NSF EIA-0196217.

## Reviewed but not bundled as third-party plugins

The following projects were evaluated for architecture and compatibility. No third-party plugin source or runtime is currently bundled from them:

- Beehave — https://github.com/bitbrain/beehave (MIT): behavior-tree AI reference.
- Phantom Camera — https://github.com/ramokz/phantom-camera (MIT): camera behavior reference; NOVA retains its own collision-aware camera rig.
- Dialogue Manager — https://github.com/nathanhoad/godot_dialogue_manager (MIT): dialogue architecture reference; NOVA uses a lightweight native dialogue overlay to avoid a runtime/editor dependency.
- Terrain3D — https://github.com/TokisanGames/Terrain3D (MIT): evaluated for future large terrain work; not adopted until Android ARM64 extension compatibility is proven.
- GDQuest 3D Third-Person Controller — https://github.com/gdquest-demos/godot-4-3d-third-person-controller: code may be studied under its code license, but its CC BY-NC-SA art assets are excluded from commercial use.

## Asset intake policy

Record each shipped asset's source, exact upstream revision, file-level license, modifications and attribution requirements. Do not ship assets with unclear provenance or incompatible terms.
