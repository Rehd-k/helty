# Upgrade to latest or a version that packages Dart >=3.12.0
FROM ghcr.io/cirruslabs/flutter:latest AS build

# Use the non-root user provided by cirruslabs
USER cirrus
WORKDIR /app

# Ensure proper permissions during copy
COPY --chown=cirrus:cirrus pubspec.* ./
RUN flutter pub get

COPY --chown=cirrus:cirrus . .
RUN flutter build web --no-wasm-dry-run --no-web-resources-cdn --pwa-strategy=none

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html

RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html index.htm; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]