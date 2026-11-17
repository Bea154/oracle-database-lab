# Lab 4 — Autopsia de mi instancia

Fuente: evidencia terminada en _15-autopsia-instancia.spool.log,
contrastada con las evidencias 11 de archivos.

## 1. Redundancia con almacenamiento compartido
Observación: hay dos control files en el mismo volumen y tres
grupos de redo con un miembro por grupo.
Riesgo: la duplicación de control files no protege frente a la
pérdida del volumen; cada grupo de redo carece de un segundo miembro.
Acción: planificar redundancia en almacenamiento independiente,
mantener copias verificadas y probar la recuperación.
Prioridad: alta para un entorno de producción.

## 2. Estadísticas de índices por comprobar
Observación: ALTURA_MAX aparece vacía para Clínica, Fintech,
Logística y Retail. NO_VALIDOS = 0 en los cinco esquemas.
Riesgo: las estadísticas ausentes o incompletas pueden dificultar
la elección de planes adecuados.
Acción: comprobar LAST_ANALYZED y recoger estadísticas donde
corresponda. No reconstruir índices sin medir la necesidad.
Prioridad: media, antes de evaluar rendimiento con carga real.

## 3. Clasificación de mensajes del alert log
Observación: cuatro mensajes ORA en 24 horas: dos ORA-00800,
un ORA-65025 y un ORA-959.
Riesgo: generar falsas alarmas con pruebas conocidas o ignorar
un incidente real por considerar todos los errores como ruido.
Acción: conservar mensajes y contexto. ORA-65025 corresponde
a la prueba de borrado de PDB abierta. Revisar los argumentos
de ORA-00800 y el texto completo de ORA-959 antes de clasificarlos.
Prioridad: media.

La instancia estaba OPEN/ACTIVE y FREEPDB1 en READ WRITE.
Estos hallazgos son propuestas de mejora; no se han aplicado
cambios adicionales como parte de esta autopsia.

### Clasificación del ORA-959
El alert log lo sitúa durante DROP TABLESPACE IF EXISTS tbs_lab4
INCLUDING CONTENTS AND DATAFILES, en la limpieza preventiva del
apartado 13. El tablespace todavía no existía y el experimento
continuó correctamente. Se clasifica como mensaje conocido de
preparación del laboratorio, sin acción correctiva pendiente.
Evidencia: registro terminado en _15-contexto-ora959.script.log.
