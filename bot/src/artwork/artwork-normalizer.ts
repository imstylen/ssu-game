import { mkdir, readFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import sharp from "sharp";

export const MAX_ARTWORK_BYTES = 10 * 1024 * 1024;
const MAX_INPUT_PIXELS = 4096 * 4096;
const ALLOWED_FORMATS = new Set(["jpeg", "png"]);

export class ArtworkNormalizer {
  readonly #directory: string;

  constructor(directory: string) {
    this.#directory = resolve(directory);
  }

  async normalize(submissionId: string, source: Buffer): Promise<string> {
    if (source.byteLength > MAX_ARTWORK_BYTES) {
      throw new Error("Artwork must be 10 MB or smaller");
    }
    const image = sharp(source, { animated: false, limitInputPixels: MAX_INPUT_PIXELS });
    const metadata = await image.metadata();
    if (!metadata.format || !ALLOWED_FORMATS.has(metadata.format)) {
      throw new Error("Artwork must be a PNG or JPEG image");
    }
    await mkdir(this.#directory, { recursive: true });
    const outputPath = join(this.#directory, `${submissionId}.png`);
    await image
      .rotate()
      .resize(1024, 1024, { fit: "cover", position: "centre" })
      .png()
      .toFile(outputPath);
    return outputPath;
  }

  async read(submissionId: string): Promise<Buffer> {
    return readFile(join(this.#directory, `${submissionId}.png`));
  }
}
