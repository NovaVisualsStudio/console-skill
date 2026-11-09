import { readFile } from 'node:fs/promises';
import { NodeIO } from '@gltf-transform/core';
import { KHRONOS_EXTENSIONS } from '@gltf-transform/extensions';
import { dequantize } from '@gltf-transform/functions';

const [input, output] = process.argv.slice(2);
if (!input || !output) throw new Error('Usage: normalize.mjs <input.glb> <output.glb>');

// CharacterCreator GLBs declare KHR_mesh_quantization. Register Khronos extensions
// before reading so glTF Transform can decode them, then dequantize for Godot.
const io = new NodeIO().registerExtensions(KHRONOS_EXTENSIONS);
const document = await io.read(input);
let sparseCount = 0;
for (const accessor of document.getRoot().listAccessors()) {
  if (accessor.getSparse()) {
    // glTF Transform materializes sparse values into the accessor's typed array on read.
    // Clearing this flag writes the complete accessor rather than sparse overrides.
    accessor.setSparse(false);
    sparseCount += 1;
  }
}
await document.transform(dequantize());
await io.write(output, document);

// Inspect the serialized GLB JSON, not just the in-memory graph, to guarantee that
// unsupported sparse storage and the quantization extension are absent from output.
const bytes = await readFile(output);
if (bytes.toString('ascii', 0, 4) !== 'glTF' || bytes.readUInt32LE(4) !== 2) {
  throw new Error('Normalizer produced an invalid GLB header.');
}
if (bytes.readUInt32LE(8) !== bytes.length) {
  throw new Error('Normalizer produced a GLB with an incorrect declared length.');
}
const jsonChunkLength = bytes.readUInt32LE(12);
const jsonChunkType = bytes.readUInt32LE(16);
if (jsonChunkType !== 0x4e4f534a || 20 + jsonChunkLength > bytes.length) {
  throw new Error('Normalizer produced a GLB without a valid leading JSON chunk.');
}
const json = JSON.parse(bytes.toString('utf8', 20, 20 + jsonChunkLength));
const sparseAccessors = (json.accessors ?? []).filter((accessor) => accessor.sparse);
if (sparseAccessors.length > 0) {
  throw new Error(`Normalizer left ${sparseAccessors.length} sparse accessors in the output.`);
}
for (const field of ['extensionsUsed', 'extensionsRequired']) {
  if ((json[field] ?? []).includes('KHR_mesh_quantization')) {
    throw new Error(`Normalizer left KHR_mesh_quantization in ${field}.`);
  }
}

console.log(`Normalized ${input}: expanded ${sparseCount} sparse accessors and removed KHR_mesh_quantization.`);
