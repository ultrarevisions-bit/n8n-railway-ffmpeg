# Stage 1: Build FFmpeg using Alpine
FROM alpine:3.22 AS ffmpeg

RUN apk add --no-cache ffmpeg \
    && mkdir -p /out/bin /out/lib \
    && cp /usr/bin/ffmpeg /usr/bin/ffprobe /out/bin/ \
    && find /lib /usr/lib -type f -name '*.so*' -exec cp -a {} /out/lib/ \; \
    && find /lib /usr/lib -type l -name '*.so*' -exec cp -a {} /out/lib/ \;

# Stage 2: n8n
FROM n8nio/n8n:2.19.2

USER root

# --------------------------------------------------
# FFmpeg
# --------------------------------------------------

COPY --from=ffmpeg /out/bin/ /opt/ffmpeg/bin/
COPY --from=ffmpeg /out/lib/ /opt/ffmpeg/lib/

RUN printf '#!/bin/sh\nLD_LIBRARY_PATH=/opt/ffmpeg/lib exec /opt/ffmpeg/bin/ffmpeg "$@"\n' \
    > /usr/local/bin/ffmpeg \
    && chmod +x /usr/local/bin/ffmpeg \
    && printf '#!/bin/sh\nLD_LIBRARY_PATH=/opt/ffmpeg/lib exec /opt/ffmpeg/bin/ffprobe "$@"\n' \
    > /usr/local/bin/ffprobe \
    && chmod +x /usr/local/bin/ffprobe

    
# --------------------------------------------------
# Node-based Edge TTS
# --------------------------------------------------

RUN npm install --global --omit=dev node-edge-tts@1.2.10 \
    && echo "===== VERIFY NODE EDGE TTS =====" \
    && node-edge-tts --version



# --------------------------------------------------
# n8n
# --------------------------------------------------

ENV N8N_PORT=5678
ENV NODE_ENV=production
ENV N8N_DIAGNOSTICS_ENABLED=false
ENV GENERIC_TIMEZONE=UTC
ENV N8N_USER_FOLDER=/home/node/.n8n

EXPOSE 5678
