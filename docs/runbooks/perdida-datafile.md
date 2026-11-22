# Recuperación de un datafile de FREEPDB1

1. **Diagnosticar.** Ante ORA-01116, ORA-01110 u ORA-27041, revisar el alert log e identificar el número y la ruta del datafile. Si aparece ORA-63999, comprobar si Oracle cerró la PDB. Avisar al DBA de guardia y al responsable del servicio.
2. **Comprobar.** Desde CDB$ROOT, consultar `SELECT log_mode FROM v$database` y `SELECT name, open_mode FROM v$pdbs`. Confirmar `ARCHIVELOG` y comprobar en RMAN que existe una copia con `LIST BACKUP OF DATAFILE 16;`. Sustituir `16` por el número afectado en otro incidente.
3. **Aislar.** Si la PDB sigue en `READ WRITE`, ejecutar `ALTER DATABASE DATAFILE 16 OFFLINE;`. Si Oracle la está cerrando, esperar a que quede en `MOUNTED` antes de restaurar.
4. **Recuperar.** En RMAN, ejecutar `RESTORE DATAFILE 16;` y `RECOVER DATAFILE 16;`. En SQL, ejecutar `ALTER DATABASE DATAFILE 16 ONLINE;`. Si `FREEPDB1` sigue en `MOUNTED`, ejecutar `ALTER PLUGGABLE DATABASE FREEPDB1 OPEN;`.
5. **Verificar.** Confirmar `READ WRITE` en `v$pdbs`. En el simulacro, comprobar en `FREEPDB1` que `ADMIN_ACADEMIA.ACA_ESTUDIANTES` conserva el estado `EGRESADO` de la fila 104 antes de devolverla a `ACTIVO`. Registrar el tiempo de recuperación y comunicar el resultado.

En el simulacro, Oracle cerró FREEPDB1. El servicio volvió en 9 segundos desde el fallo y se conservó la transacción confirmada después de la copia (RPO 0).
