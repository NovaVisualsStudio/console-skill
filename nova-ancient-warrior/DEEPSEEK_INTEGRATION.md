# DeepSeek integration for Nova Ancient Warrior

This is an **optional, read-only development assistant**, not an in-game dependency.
It reviews Git diffs and writes an advisory Markdown report. It does not edit files,
commit changes, merge pull requests, or replace Godot/Blender/CI tests.

## Supported connection modes

### 1. Hosted DeepSeek API

1. Create an API key in the official DeepSeek platform.
2. Add it to the GitHub repository as an Actions secret named `DEEPSEEK_API_KEY`.
3. Run **Actions → DeepSeek advisory code review → Run workflow**.
4. Download the `nova-ancient-warrior-deepseek-review` artifact.

The default endpoint is `https://api.deepseek.com`; the default model is
`deepseek-flash`. Model IDs can change; check the official model list and select
a currently supported identifier when dispatching the workflow.

### 2. Self-hosted open-weight model

Run a DeepSeek open-weight checkpoint behind an OpenAI-compatible inference
server such as vLLM or SGLang. Configure:

- `DEEPSEEK_BASE_URL`: the server base URL, ending before `/chat/completions`
- `DEEPSEEK_MODEL`: the model identifier exposed by that server
- `DEEPSEEK_API_KEY`: optional for a trusted local server; required if that server
  enforces authentication

For a local development run, execute from this folder:

```bash
python tools/deepseek_review.py --diff-file /path/to/change.patch --output deepseek-review.md
```

The GitHub-hosted runner cannot reach a model server bound only to your phone or
computer's `localhost`. For CI use, the inference endpoint must be securely
reachable from the runner, or the workflow must run on a properly secured
self-hosted runner. Do not expose an unauthenticated inference server publicly.

## Security and quality rules

- Never put API keys in source files, patches, logs, or committed configuration.
- Use GitHub Actions secrets for hosted API credentials.
- Send only the relevant project diff; do not include personal data or unrelated
  repository files.
- Treat model findings as suggestions. A human must inspect each proposed fix.
- A DeepSeek report is not proof that the code works. Godot import, automated
  regression tests, Android export validation, and physical-device testing remain
  separate required gates.
- This integration is manual-dispatch only to avoid unexpected API usage or cost.

## Related development skills

Use the installed fal game-development and workflow skills for original 2D
asset packs and staged media pipelines when needed. Keep Blender/Godot generation
and import tests authoritative for the actual 3D player and game scenes. Do not
add generated or third-party assets until provenance, license, file format,
rig compatibility, and Android performance are checked.

## Official references

- DeepSeek API quick start: https://api-docs.deepseek.com/quick_start/
- DeepSeek model discovery: https://api-docs.deepseek.com/api/list-models/
- DeepSeek model repositories: https://github.com/deepseek-ai
- vLLM documentation: https://docs.vllm.ai/
- SGLang documentation: https://docs.sglang.ai/
