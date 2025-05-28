# Build stage
FROM cirrusci/flutter:stable AS build

WORKDIR /app
COPY frontend/ /app
RUN flutter build web

# Serve with NGINX
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html