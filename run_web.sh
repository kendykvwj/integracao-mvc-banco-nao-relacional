#!/usr/bin/env bash
# Sobe o CRUD Rails em http://localhost:${PORT:-3001} usando o MONGODB_URI do .env
cd "$(dirname "$0")"
docker rm -f faculdade-web >/dev/null 2>&1  # derruba instancia anterior deste app
rm -f web/tmp/pids/server.pid  # pid orfao do container derrubado impede o boot
exec docker run --rm -it --name faculdade-web -p "${PORT:-3001}:3000" --env-file .env -u "$(id -u):$(id -g)" -e HOME=/tmp \
  -e BUNDLE_PATH=/app/vendor/bundle -v "$PWD/web":/app -w /app ruby:3.3 \
  bin/rails server -b 0.0.0.0
