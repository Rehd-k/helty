FROM ghcr.io/cirruslabs/flutter:latest AS build

WORKDIR /app

# Ensure git handles directories owned by root without complaints
RUN git config --global --add safe.directory /app \
    && git config --global --add safe.directory /sdks/flutter

COPY pubspec.* ./
RUN flutter pub get

COPY . .
RUN flutter build web --no-tree-shake-icons --no-wasm-dry-run --no-web-resources-cdn --pwa-strategy=none

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