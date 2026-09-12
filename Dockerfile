FROM nginx:alpine

# Copy Flutter web build output to Nginx html root
COPY build/web /usr/share/nginx/html

# SPA fallback: ensure direct URL access / refresh doesn't return 404
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