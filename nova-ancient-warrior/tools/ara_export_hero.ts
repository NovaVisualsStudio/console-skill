import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { nodeLibrary } from './node-assets';
import { buildHuman } from '../src/core/human';
import { DEFAULT_PARAMS, PRESETS } from '../src/core/params';
import { exportCharacter } from '../src/export';

const preset = PRESETS['The Yoruba Warrior'];
if (!preset) throw new Error('Ara 3D Gen preset "The Yoruba Warrior" is missing');

const params = {
  ...DEFAULT_PARAMS,
  ...preset,
  name: 'NOVA Ancient Warrior',
  seed: 20261109,
  detail: 'high' as const,
  rig: 'game' as const,
  restPose: 'A' as const,
  animations: true,
  faceBones: true,
  faceShapes: true,
  speechShapes: true,
  expression: 'determined' as const,
  weapon: 'sword' as const,
};

const library = await nodeLibrary();
const character = await buildHuman(library, params);
const exported = await exportCharacter(library, character, 'glb');
const destination = resolve(process.env.NOVA_HERO_OUTPUT ?? 'nova_hero.glb');
mkdirSync(dirname(destination), { recursive: true });
writeFileSync(destination, exported.data);
console.log(JSON.stringify({
  output: destination,
  bytes: exported.data.byteLength,
  height_m: Number(character.height.toFixed(3)),
  triangles: character.mesh.positions.length / 9,
  materials: character.mesh.materials.length,
  rig_bones: character.rig?.bones.length ?? 0,
  animation_count: params.animations ? 'all Ara clips' : 0,
}, null, 2));
