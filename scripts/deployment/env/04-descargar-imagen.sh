#!/usr/bin/env bash
set -euo pipefail
source scripts/deployment/env/00-config.sh

echo "== Descarga o confirmacion de la imagen =="
docker pull "$IMG"

echo "== Imagen local y digest =="
docker images --digests container-registry.oracle.com/database/free
