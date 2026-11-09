# Free local DeepSeek-compatible review for Nova Ancient Warrior

This is an optional, local-only, read-only development assistant. It is not an
in-game dependency and cannot call hosted or remote inference APIs.

## Zero-cost operating mode

- The client accepts only a local HTTP inference server at localhost.
- The default endpoint is http://127.0.0.1:8000/v1.
- No API key, subscription, paid endpoint, or hosted inference service is used.
- To use a real model, run an open-weight DeepSeek model locally on hardware
  you already own, using a compatible local inference server such as vLLM or
  llama.cpp. The client rejects remote endpoints to prevent accidental charges.
- Configure DEEPSEEK_BASE_URL and DEEPSEEK_MODEL only for that local server.
- Do not expose the local inference server publicly.

Run locally from this folder:

    python tools/deepseek_review.py --diff-file /path/to/change.patch --output local-model-review.md

## Quality and security

- No credentials are needed or accepted by this local-only client.
- Send only the relevant project diff; exclude personal data and unrelated files.
- Treat model findings as suggestions. A human must inspect every proposed fix.
- A model report is not proof that the code works. Godot import, automated
  regression tests, Android export validation, and physical-device testing
  remain separate required gates.
- GitHub Actions performs deterministic local mock tests only; hosted AI review
  workflows have been removed under the zero-cost policy.

## Free project tools

- Godot Engine: MIT-licensed engine.
- Blender: GPL-licensed 3D content creation suite.
- GitHub Free: use included Actions quotas and monitor usage; hosted minutes
  and artifact storage are finite, not unlimited.
- Prefer CC0/MIT/Apache-2.0 assets only after checking each asset's own license
  and Android compatibility.

## References

- DeepSeek open model repositories: https://github.com/deepseek-ai
- vLLM documentation: https://docs.vllm.ai/
- llama.cpp: https://github.com/ggml-org/llama.cpp
- Godot license: https://godotengine.org/license/
- Blender license: https://www.blender.org/about/license/