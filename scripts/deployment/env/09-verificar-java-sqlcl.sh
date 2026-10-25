#!/usr/bin/env bash
set -euo pipefail

echo "== Java =="
java -version 2>&1
echo "== JAVA_HOME =="
echo "$JAVA_HOME"
echo "== SQLcl =="
command -v sql
sql -version
