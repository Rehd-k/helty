FROM ghcr.io/cirruslabs/flutter:3.47.6 AS build

WORKDIR /app

# Copy dependency definitions
COPY pubspec.* ./

# Verify SDK version and resolve packages
RUN flutter --version
RUN flutter pub get

# Copy source code and build web bundle
COPY . .

RUN flutter build web \
    --no-tree-shake-icons \
    --no-wasm-dry-run \
    --no-web-resources-cdn \
    --pwa-strategy=none

# Production stage using Nginx
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