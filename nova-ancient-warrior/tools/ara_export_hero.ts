import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { nodeLibrary } from './node-assets';
import { buildHuman } from '../src/core/human';
import { DEFAULT_PARAMS, PRESETS } from '../src/core/params';
import { exportCharacter } from '../src/export';

const preset = PRESETS['The Soldier'];
if (!preset) throw new Error('Ara 3D Gen preset "The Soldier" is missing');

const params = {
  ...DEFAULT_PARAMS,
  ...preset,
  name: 'NOVA Ancient Warrior',
  seed: 20261109,
  age: 0.58,
  muscle: 0.9,
  weight: 0.52,
  height: 0.56,
  african: 0.35,
  asian: 0.08,
  caucasian: 0.57,
  eyes: 'blackbrown',
  eyebrows: 'eyebrow003',
  facialHair: 'short_beard',
  beardColor: '#201711',
  outfit: 'none',
  top: 'long_tunic',
  bottom: 'trousers',
  shoes: 'sandals',
  tattoos: [],
  accessories: ['crossed_straps', 'amulets', 'belt'],
  garmentStyles: {
    long_tunic: { pattern: 'solid', color: '#38291e', color2: '#b48b4c' },
    trousers: { pattern: 'solid', color: '#29272b', color2: '#b48b4c' },
  },
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
