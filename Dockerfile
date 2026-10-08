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