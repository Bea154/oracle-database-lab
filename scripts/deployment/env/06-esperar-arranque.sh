#!/usr/bin/env bash
set -euo pipefail
source scripts/deployment/env/00-config.sh

FMT='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}'

echo "== Esperando a Oracle: maximo 5 minutos =="
estado="starting"
for i in $(seq 1 60); do
  estado=$(docker inspect -f "$FMT" "$CONT_NAME")
  echo "Intento $i: $estado"
  if [ "$estado" = "healthy" ]; then
    break
  fi
  sleep 5
done

echo "== Estado final =="
docker ps -a --filter "name=$CONT_NAME" --format '{{.Names}} {{.Status}}'

echo "== Registro de arranque =="
docker logs "$CONT_NAME" 2>&1

if [ "$estado" != "healthy" ]; then
  echo "ERROR: Oracle no ha llegado a healthy."
  exit 1
fi
