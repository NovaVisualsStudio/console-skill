---
name: ltx-video-production
description: >
  Research and plan local LTX-2.3 audio-video generation workflows for lawful,
  non-restricted creative projects. Covers text/image-to-video, synchronized
  audio, shot design, model checkpoints, local inference and quality review.
  Always run the license gate before any model use. Do not use for Nova Ancient
  Warrior or other warfare/combat/weapon-related applications unless Lightricks
  gives written clarification or permission that covers the intended use.
---

# LTX-2.3 Video Production

Use this skill when the user explicitly requests LTX-2.3 or asks to plan an
open-weight audio/video generation pipeline. LTX-2.3 is a 22B-parameter
audio-video foundation model from Lightricks. Its model card lists text-to-video,
image-to-video, video-to-video and audio/video-conditioned workflows, with
synchronized audio and video generation. It offers a full development
checkpoint and distilled checkpoints (the distilled variant is documented as
an 8-step model).

## Mandatory license gate — check before generation

LTX-2.3 is **open-weight, not an unrestricted OSI-style open-source model**.

- The official inference/training code in `Lightricks/LTX-2` is Apache-2.0.
- LTX-2.3 model weights are governed by the **LTX-2 Community License Agreement**
  (not Apache-2.0). The Gemma 3 text encoder is a separate dependency with its
  own Google license.
- The LTX-2 Community License requires a paid commercial-use agreement for
  entities with annual revenue of at least USD 10 million.
- Attachment A restricts use for military/warfare applications, weapons
  development, and uses connected with activities that may cause death,
  personal injury, or severe physical/environmental damage.
- Do not assume fictional games, trailers, cutscenes, combat animation,
  weapon/action sequences, or game marketing are exempt. The license does not
  expressly state a video-game exception.
- **Project-specific stop:** Nova Ancient Warrior is a fictional combat game.
  Do not download, run, fine-tune, or use LTX-2.3 outputs for its characters,
  combat, weapons, enemies, levels, cutscenes, trailers, promotional assets,
  or other project materials unless Lightricks provides written clarification
  or permission explicitly covering this intended game use. Do not attempt to
  route around this restriction by generating assets under a different label.
- For other projects, check the current model-card license and Acceptable Use
  Policy again immediately before use. Do not rely on this summary as legal
  advice.

Primary license and model references:
- Model card: https://huggingface.co/Lightricks/LTX-2.3
- Official code and inference pipelines: https://github.com/Lightricks/LTX-2
- LTX-2 Community License: https://github.com/Lightricks/LTX-2/blob/main/LICENSE-2
- Official model overview: https://ltx.io/model/ltx-2-3

## Capability and pipeline notes

- Text-to-video and image-to-video generation.
- Joint audio/video generation and synchronized audio output.
- Full 22B development checkpoint for flexibility/fine-tuning.
- Distilled 22B checkpoint for faster, fewer-step inference.
- Spatial and temporal upscalers are available for supported workflows.
- The official repository includes inference pipelines and LoRA training
  utilities. Inspect the exact checkpoint and CLI schema before execution;
  do not mix LTX-2.3 checkpoints, LTX-2.5 components, or LoRAs trained for
  another model version.

## Hardware and zero-cost policy

- Treat LTX-2.3 as a large GPU workload. It is not a practical on-device
  Android/low-memory-phone model.
- The official repository documents a Python/CUDA/PyTorch GPU environment;
  check its current README and system requirements before setup.
- Do not download tens of gigabytes of weights until compatible storage,
  GPU memory, system RAM and a usable CUDA GPU are confirmed.
- Respect the repository's zero-cost policy: do not use metered APIs, paid
  hosted inference, paid GPU rentals, or paid services without explicit
  approval. Open weights do not make cloud compute free.
- If the user only has a phone or no suitable GPU, provide a workflow plan or
  use an already available free, license-compatible alternative. Never claim
  local inference succeeded without an actual run.

## Production workflow (only after the license gate passes)

1. Confirm the exact LTX-2.3 checkpoint, current license, target output,
   duration, aspect ratio and whether audio is required.
2. Verify hardware and disk capacity; pin the official repository revision
   and Python/CUDA/PyTorch environment.
3. Choose the distilled checkpoint for iteration; use the full development
   checkpoint only when its quality/control benefits justify the compute.
4. Anchor image-to-video with an approved reference frame when consistency
   matters. Keep each shot focused on one principal action and camera move.
5. Follow model constraints: width and height divisible by 32; frame count
   divisible by 8 plus 1. Check the current model card for any updated rules.
6. Generate a low-cost short draft first. Do not start a batch until the
   first output passes visual and audio review.
7. Review frame continuity, subject identity, anatomy, motion, camera path,
   unwanted objects, temporal flicker, audio artifacts and audio/video sync.
8. Export an edit-ready master and record checkpoint, repository revision,
   prompt, settings, output hash and license/provenance notes.

## Acceptance checklist

- [ ] Intended use passes the current LTX license and Acceptable Use Policy.
- [ ] Exact checkpoint and all companion components have compatible licenses.
- [ ] Hardware and storage are confirmed before downloading.
- [ ] No paid service or metered API was used without explicit approval.
- [ ] Visual continuity and audio/video synchronization were inspected.
- [ ] Outputs and any derivatives are distributed only under applicable terms.
