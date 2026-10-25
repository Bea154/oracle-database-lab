#!/usr/bin/env bash
set -euo pipefail

echo "== Sistema operativo y arquitectura =="
uname -s
uname -m
grep -qi microsoft /proc/version && echo "Entorno: Ubuntu en WSL 2"
grep PRETTY_NAME /etc/os-release

echo "== Shell =="
echo "$SHELL"

echo "== Espacio libre =="
df -h .

echo "== Memoria =="
free -h

echo "== Herramientas =="
for t in git gh curl wget unzip zip tree rsync ncdu jq htop lsof ss dig ping tmux vim nano shellcheck; do
  if command -v "$t" >/dev/null; then
    echo "OK $t"
  else
    echo "FALTA $t"
    exit 1
  fi
done

echo "== Git =="
git --version
git config --global user.email
