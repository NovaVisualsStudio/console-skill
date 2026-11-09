# Android installation and first-run checklist

This is the signed **debug** build of Nova Ancient Warrior, exported by the Godot 4.7.2 Android workflow. It is a sideloading test build, not a Play Store release.

## Verified build identity

- App: Nova Ancient Warrior
- Package: `com.novavisualsstudio.novaancientwarrior`
- Version: `0.1.0-debug` (version code 1)
- Android ABIs: ARMv7 (`armeabi-v7a`) and ARM64 (`arm64-v8a`)
- Renderer: Godot GL Compatibility (OpenGL ES path)
- Workflow artifact: `nova-ancient-warrior-android-debug`
- CI verifies the APK archive, v2/v3 APK signature and package identifier before upload.

## Install on an Android phone

1. Download `nova-ancient-warrior-debug.apk` from the successful **Nova Ancient Warrior Android debug APK** GitHub Actions run.
2. Open the downloaded APK from the phone's Downloads notification or Files app.
3. If Android blocks the installer, open **Settings → Apps → Special app access → Install unknown apps**, select the browser or file manager used to download it, and enable **Allow from this source**. The exact labels can vary by Android version and manufacturer.
4. Return to the APK and tap **Install**.
5. Open **Nova Ancient Warrior** from the app drawer.

Only install APKs obtained from the repository's trusted workflow artifact or another verified release source.

## Important debug-build update behaviour

The workflow creates a fresh temporary debug signing key for each build. Android will reject an in-place update if the newly downloaded APK is signed by a different temporary key. To install a later CI build in that case, uninstall the previous debug build first and then install the new APK. **Uninstalling removes local app data and saved campaign progress.** Export or back up any important save data before uninstalling.

## First-run device test

On the phone, verify the following manually:

- The app opens and reaches the title/game scene without closing.
- Touch movement responds in all directions.
- Light attack, heavy attack, dodge, guard, parry and target lock respond.
- Music and effects are audible with the phone volume enabled.
- Pause/resume and screen rotation do not break the game.
- Complete one encounter, close/reopen the app and verify checkpoint resume.
- Play for 10–15 minutes and watch for overheating, stutter, visual corruption or crashes.

Record the phone model, Android version, whether the game launched, any crash message, and approximate frame pacing. CI headless tests and APK signature checks do **not** replace this physical-device test.

## Current known limitations

- The project is a playable vertical-slice prototype, not a finished commercial-scale action game.
- Three chapters and nine encounters exist, but chapter spaces still reuse a procedural combat-arena structure; authored exploration, traversal and puzzles remain future work.
- The current generated hero is stylized low-poly, with 20 bones and ten authored animation clips. It is not yet a photorealistic human.
- A separate experimental motion-capture candidate has 61 bones and one clip. It has passed a structural import smoke test but has **not** been approved as the player rig or retargeted into the ten-clip animation library.
- Android renderer settings target 720p and a 60 FPS cap. Actual frame rate, thermal behaviour, battery use, touch feel and audio output have not yet been measured on a physical device.

## Reproducible source build

Open `nova-ancient-warrior/project.godot` with Godot 4.7.2. Install the matching Android export templates and Android SDK/JDK 17, then export the `Android Debug` preset. The repository workflow is the reference for the pinned CI toolchain.
