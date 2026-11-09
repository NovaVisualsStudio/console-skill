import { NodeIO } from '@gltf-transform/core';
import { dequantize } from '@gltf-transform/functions';

const [input, output] = process.argv.slice(2);
if (!input || !output) throw new Error('Usage: normalize.mjs <input.glb> <output.glb>');
const io = new NodeIO();
const document = await io.read(input);
let sparseCount = 0;
for (const accessor of document.getRoot().listAccessors()) {
  if (accessor.getSparse()) {
    accessor.setSparse(false);
    sparseCount += 1;
  }
}
await document.transform(dequantize());
await io.write(output, document);
console.log(`Normalized ${input}: expanded ${sparseCount} sparse accessors and dequantized vertex attributes.`);
