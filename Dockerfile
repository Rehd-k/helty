FROM ghcr.io/cirruslabs/flutter:3.47.5 AS build

WORKDIR /app

COPY pubspec.* ./

RUN flutter --version
RUN flutter pub get

COPY . .

RUN flutter build web \
    --no-tree-shake-icons \
    --no-wasm-dry-run \
    --no-web-resources-cdn \
    --pwa-strategy=none

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