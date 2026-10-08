FROM ghcr.io/cirruslabs/flutter:stable AS build

# Switch to cirrus user to avoid root permission warnings
USER cirrus
WORKDIR /app

# Upgrade Flutter to pull the latest stable Dart SDK (>=3.13.0)
RUN flutter channel stable && flutter upgrade

# Copy dependency definitions
COPY --chown=cirrus:cirrus pubspec.* ./

# Verify SDK version and resolve packages
RUN flutter --version
RUN flutter pub get

# Copy source code and build web bundle
COPY --chown=cirrus:cirrus . .

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