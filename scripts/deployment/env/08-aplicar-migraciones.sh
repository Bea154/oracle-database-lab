#!/usr/bin/env bash
set -euo pipefail
source scripts/deployment/env/00-config.sh
set -a
source config/.env
set +a

CONN="sys/$ORACLE_PWD@localhost:1521/$SERVICE_PDB"

for MIG in V000__setup_entornos_negocio V001__create_esquemas_negocio; do
  echo ">> Aplicando $MIG"
  LOG="$EVID/spool/$(ts)_08-$MIG.spool.log"
  if ! docker exec -i "$CONT_NAME" sqlplus -L -s "$CONN" as sysdba \
    < "database/migrations/$MIG.sql" 2>&1 | tee "$LOG"; then
    echo "ERROR en $MIG: revisa $LOG antes de continuar"
    exit 1
  fi
done

echo ">> Migraciones aplicadas correctamente."
