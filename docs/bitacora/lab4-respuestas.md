# Lab 4 — Respuestas y observaciones

## 1. ¿Por qué la copia es consistente?

Cerramos Oracle con SHUTDOWN IMMEDIATE para cerrar las sesiones,
deshacer las transacciones sin confirmar y escribir en disco los
cambios confirmados pendientes. Los archivos dejan de cambiar
durante la copia y quedan en un estado consistente.

Evidencia: 20261116T192550Z_00-backup-lab3.script.log muestra
"ORACLE instance shut down" antes de la copia del volumen.

Copiar los archivos con la base abierta mediante este procedimiento
no garantiza una copia consistente, porque podrían cambiar mientras
se copian.

## Observaciones de mi copia

- Tamaño mostrado: 544 MB.
- Archivos fuera del volumen: 0.
- Verificación SHA-256: todos los archivos muestran OK.
- Evidencia: 20261116T193010Z_00-verificacion-backup.script.log.
- Todavía no se ha probado la restauración.
