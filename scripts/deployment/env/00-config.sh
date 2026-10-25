#!/usr/bin/env bash
# Constantes del proyecto. No contiene contraseñas.

export CONT_NAME="oralab-26ai"
export VOL_NAME="oralab-26ai-data"
export IMG="container-registry.oracle.com/database/free:latest"
export PORT_DB=1521
export PORT_ORDS=8181
export SERVICE_CDB="FREE"
export SERVICE_PDB="FREEPDB1"
BACKUP_DIR="$(pwd)/backups"
export BACKUP_DIR
export EVID="docs/bitacora/evidencia"

ts() { date -u +%Y%m%dT%H%M%SZ; }

# ORDS: servidor web en Ubuntu
export ORDS_HOME="/opt/oracle/ords"
export ORDS_CONFIG="/etc/ords/config"
export ORDS_LOGS="/var/log/ords"
export ORDS_PORT=8080
