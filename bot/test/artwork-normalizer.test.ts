import assert from "node:assert/strict";
import { mkdtemp, readFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import sharp from "sharp";
import { ArtworkNormalizer } from "../src/artwork/artwork-normalizer.js";

test("normalizes JPEG artwork to a metadata-free 1024px PNG", async () => {
  const directory = await mkdtemp(join(tmpdir(), "card-artwork-"));
  const source = await sharp({
    create: { width: 1600, height: 900, channels: 3, background: "#336699" },
  }).jpeg().withMetadata({ orientation: 6 }).toBuffer();
  const normalizer = new ArtworkNormalizer(directory);

  const outputPath = await normalizer.normalize("submission", source);
  const output = sharp(await readFile(outputPath));
  const metadata = await output.metadata();

  assert.equal(metadata.format, "png");
  assert.equal(metadata.width, 1024);
  assert.equal(metadata.height, 1024);
  assert.equal(metadata.orientation, undefined);
});

test("rejects formats outside the PNG and JPEG allowlist", async () => {
  const directory = await mkdtemp(join(tmpdir(), "card-artwork-"));
  const source = await sharp({
    create: { width: 16, height: 16, channels: 3, background: "red" },
  }).webp().toBuffer();

  await assert.rejects(new ArtworkNormalizer(directory).normalize("submission", source), /PNG or JPEG/);
});
