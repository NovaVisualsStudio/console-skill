# Poly Haven environment textures

Both texture sets are dedicated to the public domain under **CC0 1.0 Universal**.

| Asset | Author credit | Official source | Maps bundled at build time |
|---|---|---|---|
| Stone Wall | Charlotte Baglioni (photography), Dario Barresi (processing) | https://polyhaven.com/a/stone_wall | Diffuse, OpenGL normal, roughness - 1K JPG |
| Rock Tile Floor | Charlotte Baglioni | https://polyhaven.com/a/rock_tile_floor | Diffuse, OpenGL normal, roughness - 1K JPG |

The files are downloaded from the Poly Haven public API and its official download CDN. The fetcher writes per-texture Godot import sidecars before the first import: VRAM compression, mipmap generation, a 1K size cap, and explicit RGTC compression for OpenGL normal maps. The fetcher accepts only HTTPS files on `dl.polyhaven.org` in the `Textures/jpg/1k` path, checks JPEG signatures and verifies each file against the MD5 supplied by the API. No paid account, subscription, token, or API key is used.

The game displays **“Powered by Poly Haven”** in its HUD, following the public API credit request. The API is used only during asset preparation; no connection to Poly Haven is required at runtime.

Licence: https://creativecommons.org/publicdomain/zero/1.0/
API information: https://polyhaven.com/our-api
