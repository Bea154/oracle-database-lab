#!/usr/bin/env bash
set -euo pipefail

echo "== Cliente y servidor de Docker =="
docker version

echo "== Prueba real con hello-world =="
docker run --rm hello-world
