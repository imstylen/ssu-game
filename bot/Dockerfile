FROM node:24.19.0-bookworm-slim AS build

WORKDIR /app
COPY bot/package.json bot/package-lock.json ./
RUN npm ci
COPY bot/tsconfig.json ./
COPY bot/src ./src
RUN npm run build

FROM node:24.19.0-bookworm-slim AS runtime

ARG GODOT_VERSION=4.4.1
ARG GODOT_SHA512=ef4e76880a514257175544952c61191106fdef3095b909bafed9fcbeb230c3e5533920a0f3012882dd4bbde83028a67549825794e2d2c3cf76eba7918b71370e

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates curl git unzip \
    && rm -rf /var/lib/apt/lists/* \
    && curl --fail --location --silent --show-error \
      --output /tmp/godot.zip \
      "https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" \
    && echo "${GODOT_SHA512}  /tmp/godot.zip" | sha512sum --check \
    && unzip -q /tmp/godot.zip -d /usr/local/bin \
    && mv "/usr/local/bin/Godot_v${GODOT_VERSION}-stable_linux.x86_64" /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm /tmp/godot.zip

WORKDIR /app
COPY bot/package.json bot/package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --from=build /app/dist ./dist

RUN mkdir -p /data/artwork /data/repository \
    && chown -R node:node /data /app

USER node
VOLUME ["/data"]
ENV DATABASE_PATH=/data/card-bot.sqlite \
    ARTWORK_DIRECTORY=/data/artwork \
    WORKING_CHECKOUT=/data/repository \
    GODOT_EXECUTABLE=godot

CMD ["node", "dist/src/index.js"]
