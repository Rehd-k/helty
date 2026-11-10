# Stage 1: Build Flutter Web using official Flutter stable
FROM ubuntu:24.04 AS build

# Install prerequisites
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Clone Flutter stable directly from official repo
RUN git clone https://github.com/flutter/flutter.git --depth 1 -b stable /sdks/flutter
ENV PATH="/sdks/flutter/bin:$PATH"

# Pre-download web artifacts
RUN flutter precache --web

WORKDIR /app

COPY pubspec.* ./
RUN flutter pub get

COPY . .

# .env is gitignored, so Coolify/git builds never have it — but pubspec
# declares it as a Flutter asset, so the file must exist before `flutter build`.
# Pass these as Coolify "Build Arguments" (or build-time env vars).
ARG ORG_NAME=Ibom Multispecialty Hospital
ARG ORG_ADDRESSES=Ikot Ekpene - Uyo Rd, Uyo, Akwa Ibom
ARG ORG_PHONES=0802 181 4674
ARG ORG_EMAILS=info@imsh.ng
ARG ORG_WEBSITE=https://imsh.ng
ARG ORG_LOGO=assets/imsh.png
ARG API_BASE_URL=https://api.imsh.ng
# ARG ORG_TAGLINES=OrthoConsult365 Specialist Hospital is a leading provider of orthopedic services in Uyo, Nigeria. We offer a wide range of services including orthopedic surgery, physical therapy, and rehabilitation.

# ARG ORG_NAME=OrthoConsult365 Specialist Hospital
# ARG ORG_ADDRESSES=14 Ime Okon Avenue Osongama Estate Uyo 
# ARG ORG_PHONES=0803 548 4144
# ARG ORG_EMAILS=orthoconsult365@gmail.com
# ARG ORG_WEBSITE=https://orthoconsult365.com
# ARG ORG_LOGO=assets/logo.png
# ARG API_BASE_URL=https://orthoconsult-api.imsh.ng;
# ARG ORG_TAGLINES=OrthoConsult365 Specialist Hospital is a leading provider of orthopedic services in Uyo, Nigeria. We offer a wide range of services including orthopedic surgery, physical therapy, and rehabilitation.

RUN printf '%s\n' \
    "ORG_NAME=${ORG_NAME}" \
    "ORG_ADDRESSES=${ORG_ADDRESSES}" \
    "ORG_PHONES=${ORG_PHONES}" \
    "ORG_EMAILS=${ORG_EMAILS}" \
    "ORG_WEBSITE=${ORG_WEBSITE}" \
    "ORG_LOGO=${ORG_LOGO}" \
    "API_BASE_URL=${API_BASE_URL}" \
    "ORG_TAGLINES=${ORG_TAGLINES}" \
    > .env \
    && test -n "${API_BASE_URL}" || (echo "ERROR: API_BASE_URL build arg is required for release web builds" >&2; exit 1)

RUN flutter build web \
    --no-tree-shake-icons \
    --no-wasm-dry-run \
    --no-web-resources-cdn \
    --pwa-strategy=none

# Stage 2: Serve via Nginx
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

RUN printf '%s\n' \
'server {' \
'    listen 80;' \
'    server_name localhost;' \
'    root /usr/share/nginx/html;' \
'    index index.html index.htm;' \
'    location / {' \
'        try_files $uri $uri/ /index.html;' \
'    }' \
'}' \
> /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
