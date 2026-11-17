# Android installation and first-run checklist

This is the signed **debug** build of Nova Ancient Warrior, exported by the Godot 4.7.2 Android workflow. It is a sideloading test build, not a Play Store release.

## Verified build identity

- App: Nova Ancient Warrior
- Package: `com.novavisualsstudio.novaancientwarrior`
- Version: `0.1.0-debug` (version code 1)
- Android ABI: **ARM64 only** (`arm64-v8a`); ARMv7, x86 and x86_64 are not packaged.
- Renderer: Godot GL Compatibility (OpenGL ES path)
- Workflow artifact: `nova-ancient-warrior-android-debug`
- The workflow imports the project, runs gameplay/asset smoke tests, exports the APK, and verifies its package metadata, signature and ARM64 native library before publishing the artifact.

## Download and install

1. Open the latest successful **Nova Ancient Warrior Android debug APK** workflow run in GitHub Actions.
2. In the run's **Artifacts** section, select `nova-ancient-warrior-android-debug` to download the ZIP.
3. Extract `nova-ancient-warrior-debug.apk` from the ZIP.
4. Open the APK on the phone. If Android blocks installation, open **Settings → Apps → Special app access → Install unknown apps**, select the browser or file manager used to open the APK, and enable **Allow from this source**. Labels vary by Android version and manufacturer.
5. Tap **Install**, then open **Nova Ancient Warrior** from the app drawer.

Install only an APK obtained from the repository's successful workflow artifact or a separately verified release source. ARM64 support is required; older 32-bit-only Android devices are not supported by this build.

## Important debug-build update behaviour

The workflow creates a fresh temporary debug signing key for each build. Android may reject an in-place update when the newly downloaded APK is signed by a different temporary key. To install a later CI build in that case, uninstall the previous debug build first and then install the new APK. **Uninstalling removes local app data and saved campaign progress.** Back up any important save data before uninstalling.

## First-run device test

On the phone, verify the following manually:

- The app opens and reaches the title screen without closing.
- Touch movement responds in all directions and the camera orbit does not interfere with action buttons.
- Light attack, heavy attack, dodge, guard, parry and target lock respond.
- Music and effects are audible with the phone volume enabled.
- Pause/resume and screen rotation do not break the game.
- Complete one encounter, close/reopen the app and verify checkpoint resume.
- Play for 10–15 minutes and watch for overheating, stutter, visual corruption or crashes.

Record the phone model, Android version, whether the game launched, any crash message, and approximate frame pacing. CI headless tests and APK signature checks do **not** replace this physical-device test.

## Current known limitations

- The project is a playable vertical-slice prototype, not a finished commercial-scale action game.
- Three chapters and nine encounters exist, but the chapters still reuse a procedural combat-arena structure with different dressing; they are not yet three fully authored exploration levels with complete traversal and puzzle spaces.
- The active hero asset is an Ara-generated humanoid GLB: 69-bone rig, 16 curated animation clips, 46,032 triangles and textured PBR materials. It passes automated import/animation checks, but final visual, deformation, weapon-grip and animation sign-off remains open. It must not be described as a finished photorealistic character.
- Android MID is configured with a 45 FPS cap and conservative lighting; optional HIGH uses a 60 FPS cap with glow, shadows and a larger environment budget. These are caps/settings, not measured performance guarantees.
- Actual frame rate, frame pacing, thermal behaviour, battery use, touch feel and audio output have not yet been measured on a physical device.

## Reproducible source build

Open `nova-ancient-warrior/project.godot` with Godot 4.7.2. Install the matching Android export templates and Android SDK/JDK 17, then export the `Android Debug` preset. The repository workflow is the reference for the pinned CI toolchain.
