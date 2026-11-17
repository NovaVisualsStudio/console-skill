# Zero-Cost Policy

This policy applies to every project in this repository and every future project.

## Mandatory rules
- Zero monetary cost is the default and requirement: no subscriptions, paid APIs, metered model inference, paid assets, paid plugins, or paid build services.
- Replace paid services with suitable maintained free/open-source alternatives after checking license, compatibility, security, and quality.
- If no suitable free alternative exists, disable or omit that feature and clearly report the limitation. Never silently fall back to a paid service.
- Local open-weight AI models are allowed only when run on hardware already owned by the project owner. Do not call metered hosted inference APIs.
- Use GitHub Free and other free tiers only within their included quotas. Avoid workflows or storage that could trigger overage charges; a free trial or expiring credit is not a zero-cost solution.
- Do not request, expose, or commit payment details, API keys, signing keys, tokens, or other credentials.
- Recheck the cost and licensing status of tools and assets before adoption because terms can change.

## Preferred stack
- Godot Engine and Blender for game development and 3D production.
- Python, Git, and local testing tools for automation and validation.
- GitHub Free for source control and CI within its included limits.
- CC0, MIT, Apache-2.0, and similarly permissive assets only after verifying the license of each individual asset.
- Local open-weight models where existing hardware can run them adequately.

## Quality rule
Free does not mean acceptable at any cost to quality or safety. If a free replacement is incompatible, insecure, unreliable, or too resource-intensive, keep the feature disabled and explain what is missing rather than introducing a paid dependency.
