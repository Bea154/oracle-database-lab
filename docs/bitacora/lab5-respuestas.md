# Lab 5 · Oracle DBA Workflow II

Issue #9. La verificación final (evidencia 16) devolvió `TODO OK`.

## Preguntas de comprobación

1. **Copia previa.** En el Lab 3 había cinco datafiles fuera del volumen. En el paso 6 de la copia del Lab 4 apareció «ninguno». Esto demuestra que la reubicación dejó todos los archivos de la base dentro del volumen. La copia ocupó 679 MB (evidencia 00).
2. **Factor de bloqueo.** `CLIENTE` tiene 100.000 filas en 1.517 bloques, unas 66 filas por bloque. `PEDIDO` tiene 1.000.000 de filas en 5.320 bloques, unas 188 filas por bloque. En `PEDIDO` caben casi tres veces más filas por bloque porque cada fila ocupa de media 32 bytes, frente a 102 en `CLIENTE` (`01-perfil-tiendasur`, líneas 6–7).
3. **Medición.** La primera ejecución analiza la consulta y calienta la caché. Medir la segunda permite comparar las lecturas en condiciones más estables. La consulta por clave primaria devolvió una fila con 4 lecturas lógicas y 0 físicas (evidencia 01).
4. **Altura y ramificación.** `IX_PED_CLIENTE` tiene 3 niveles (`BLEVEL = 2`), 2.216 hojas y un fan-out real de 370, calculado como `(2.216 + 6 − 1) / 6` y redondeado. Con mil millones de filas y 451 entradas por hoja habría unas 2,22 millones de hojas. Si se mantiene el fan-out, se estiman 4 niveles, porque `370²` queda por debajo del número de hojas y `370³` lo supera (`02-anatomia-indice`, líneas 19–23).
5. **ROWID en la hoja.** La primera entrada de `PK_CLIENTE` (`row#0`) tiene la clave `c1 02`, correspondiente al cliente 1, y el ROWID `00 00 03 1b 00 00`. Los primeros cuatro bytes identifican el bloque 795 y los últimos dos indican la ranura 0. El número de archivo es implícito porque el tablespace bigfile contiene un único datafile (`02-anatomia-indice`, líneas 136–147).
6. **Tipos de índice.** En Q13, el índice único por DNI redujo las lecturas lógicas de 1.523 a 3 para devolver una fila. En Q7, el índice por cliente hizo 15 lecturas, el compuesto por cliente y fecha hizo 7 y el de cobertura hizo 3, porque devolvió las cuatro filas desde el propio índice. En Q1, el índice funcional redujo las lecturas de 1.486 a 4 al indexar `UPPER(email)`, la expresión del filtro (`03-tipos-indice`, líneas 6–8, 28–32 y 38–40).
7. **Agrupamiento.** Los pedidos se cargaron ordenados por fecha, de modo que claves de fecha próximas suelen apuntar a filas del mismo bloque. Los pedidos de cada cliente están dispersos. Un `REBUILD` del índice conserva la ubicación física de las filas. Para mejorar su agrupamiento habría que reorganizar la tabla (evidencia 04).
8. **Punto de equilibrio.** El recorrido completo hizo 5.232 lecturas. Con mal CF, el índice hizo 4.875 al 0,5 % y 9.920 al 1 %. El cruce quedó entre el 0,5 % y el 1 %, cerca del 0,53 % teórico. Oracle eligió el recorrido completo a partir del 0,2 % medido. Con buen CF, el cruce quedó entre el 50 % (3.938 lecturas) y el 100 % (7.875 lecturas) (evidencia 04).
9. **Comodines.** `Gonz%` delimita un rango en el B-tree, pero acceder a las filas por ROWID costó 2.024 lecturas. `%ez` hizo 1.523 con recorrido completo. Los filtros devolvieron conjuntos distintos, con 2.056 y 18.902 filas respectivamente (evidencia 05).
10. **Coste de escritura.** Al insertar 2.000 filas, el estado inicial con 4 índices registró 20.291 bloques modificados. La propuesta con 9 índices registró 40.320 y V005, con 5 índices, registró 24.675 (`06-indices`, líneas 7, 20 y 140). Descarté mantener `IX_PED_CLI_FEC` junto al índice de cobertura porque comparte su prefijo y, en Q7, el de cobertura hizo 3 lecturas frente a 7 del compuesto. `IX_PED_CLIENTE` también queda cubierto por ese prefijo y en Q7 hizo 15 lecturas. Retiré `IX_PED_IMPORTE` tras probarlo como invisible con Q2, cuyo filtro es por fecha.
11. **Divisiones y patrón cola.** En `07a-grafico-IX_AZAR`, el mapa mezcla tramos `-` y `=` a lo largo del índice, coherente con divisiones 50/50 y hojas con distintos grados de llenado. En `07a-grafico-IX_CRECIENTE` predominan los `#` (90 % o más), coherente con divisiones 90/10 al insertar claves crecientes. En `07b-grafico-IX_COLA-antes`, la izquierda casi vacía y la derecha llena muestran que se borraron claves antiguas y se añadieron claves altas. Tras el remedio, `07c-grafico-IX_COLA-despues` mostró un mapa uniforme de `=`.
12. **Remedio.** En horario de servicio elegiría `COALESCE` para consolidar hojas y permitir que el índice reutilice espacio. Compararía después los gráficos de ocupación para comprobar el efecto (evidencia 07).

13. **Checkpoint.** Oracle compara el SCN de checkpoint del control file con el de la cabecera del datafile. Tras forzar el checkpoint, ambos coincidieron en 6.408.090 en los datafiles de lectura/escritura mostrados. El `CURRENT_SCN` era 6.408.130 (evidencia 08).
14. **Control files.** Las tres copias permitieron recuperar `control03.ctl` desde una copia sana. Las tres comparten volumen, por lo que perder el volumen afectaría a todas. En producción las distribuiría entre dispositivos independientes (evidencias 09 y 14b).
15. **Redo.** `CURRENT` es el grupo donde escribe LGWR. `ACTIVE` todavía se necesita para la recuperación de instancia. `INACTIVE` ya no se necesita para esa recuperación y puede reutilizarse cuando se cumplan los requisitos de archivado. Oracle rechazó borrar el grupo actual (ORA-01623), borrar uno de sus miembros (ORA-01609) y borrar un grupo pendiente de archivar (ORA-00350) (evidencia 10).
16. **FRA llena.** ORA-19815 avisa de presión de espacio. Cuando se agota la cuota, aparece ORA-19809 y el archivado puede fallar con ORA-16038. Si el siguiente grupo de redo sigue pendiente de archivar, las sesiones que generan redo tienen que esperar. La cuota configurada en el laboratorio fue de 4.096 MB (evidencia 11).
17. **Lectura consistente.** Mientras A tenía pendiente el cambio de la fila 101 a `EGRESADO`, el `SELECT` normal de B leyó `ACTIVO` sin esperar, usando la versión confirmada reconstruida con undo. A usaba 1 bloque y 1 registro de undo y mantenía bloqueos TM modo 3 y TX modo 6. Cuando B pidió `FOR UPDATE WAIT 3`, recibió ORA-00054 porque A mantenía el bloqueo de la fila. Después del `COMMIT` de A, B leyó `EGRESADO` (`12-lectura-consistente`, pasos 1–5).
18. **Undo y redo.** Para 10.000 filas, `INSERT` usó 140 bloques de undo, `UPDATE` 71 y `DELETE` 427. Borrar exige guardar la información necesaria para reconstruir las filas y sus entradas de índice. Deshacer también modifica bloques, por eso los tres `ROLLBACK` generaron 356, 751 y 4.701 KB de redo respectivamente (evidencia 12).
19. **Write-ahead logging.** El `UPDATE` y su COMMIT generaron 8.531 KB de redo y cinco escrituras de LGWR. Quedaron 231 bloques sucios de la tabla. Después del checkpoint, DBWn escribió 618 bloques en toda la instancia y quedaron cero bloques sucios de la tabla. La durabilidad del COMMIT se apoya en el redo persistido. El checkpoint lleva los cambios de los bloques a los datafiles (evidencia 13).
20. **Caída de instancia.** El alert log registró el escaneo y la aplicación del redo. El roll forward rehízo cambios y el roll back deshizo la transacción pendiente. La fila 102 conservó `EGRESADO`, su valor confirmado. La fila 103 quedó en `ACTIVO` (evidencia 14a).
21. **Restauración.** C recuperó 60.000 matrículas en 171 s, con 1 s entre la copia y el fallo. D recuperó el datafile en 9 s desde el fallo y conservó el cambio confirmado de la fila 104 posterior a la copia. C restauró el volumen completo. D restauró un archivo y aplicó redo (evidencias 14c y 14d).
22. **Alert log.** En el bloque 5 de `15-healthcheck`, ORA-00202 identificó `control03.ctl` y ORA-205 registró el fallo al montar en el simulacro B. ORA-01110 identificó el datafile 16 (`academia01.dbf`) y ORA-63999 registró el fallo de medio durante D. En esa misma ventana aparecieron dos ORA-01113 para el archivo 25, que requería recuperación. Los ORA-00800 de LGWR y VKTM (`Set Priority Failed`) fueron avisos de prioridad del entorno del laboratorio. Tras los simulacros, la verificación final dio `TODO OK`.

## Simulacro S1–S26

- **S1 · B.** Un CF cercano al número de filas indica que el recorrido por clave cambia de bloque de tabla casi en cada fila.
- **S2 · A y C.** Un índice basado en función admite `UPPER(email)`. Si los emails están normalizados a minúsculas, comparar `email` con `LOWER(:e)` permite usar el índice sobre la columna.
- **S3 · B.** Oracle aplica `TO_NUMBER` a la columna de texto al compararla con un número.
- **S4 · B.** Una columna con pocos valores y pocas escrituras concurrentes encaja con un índice bitmap.
- **S5 · B.** El skip scan explora por separado los pocos valores posibles de la primera columna.
- **S6 · B.** Un índice invisible permite observar el rendimiento y volver rápidamente a hacerlo visible.
- **S7 · A y C.** `COALESCE` consolida hojas y `SHRINK SPACE` compacta el segmento cuando su configuración lo permite.
- **S8 · B.** La clave invertida reparte las inserciones secuenciales entre hojas y pierde el orden original necesario para búsquedas por rango.
- **S9 · C.** Actualizar una columna ajena a los índices deja intactas sus entradas.
- **S10 · B.** El factor de ramificación determina cuántos bloques puede alcanzar cada nivel.
- **S11 · A y C.** Una IOT almacena las filas en el índice de la clave primaria y evita un acceso separado al segmento de tabla.
- **S12 · B.** Oracle compara el SCN de checkpoint del control file con el de la cabecera del datafile.
- **S13 · C.** CKPT registra el checkpoint en los control files y las cabeceras.
- **S14 · B y E.** `V$INSTANCE` y `V$PARAMETER` muestran información de la instancia ya iniciada.
- **S15 · B.** Oracle activa ARCHIVELOG con la base montada y después la abre.
- **S16 · B.** `CLEAR LOGFILE` reinicializa un grupo inactivo cuyo redo ya se archivó.
- **S17 · A y C.** Undo reconstruye versiones anteriores para lectura consistente y consultas `AS OF`.
- **S18 · B.** La recuperación debe poder rehacer los bloques de undo antes de deshacer cambios pendientes.
- **S19 · A.** Con el COMMIT síncrono, LGWR escribe el redo de la transacción antes de confirmar.
- **S20 · A.** Reducir el objetivo de MTTR impulsa checkpoints incrementales para reducir el trabajo de recuperación.
- **S21 · B.** Si ARCn no puede archivar, los grupos pendientes no se pueden reutilizar.
- **S22 · B.** Poner offline el datafile de aplicación aísla el daño si la PDB sigue abierta.
- **S23 · B.** Un datafile de SYSTEM se restaura y recupera con la base montada antes de abrirla.
- **S24 · B.** En el escenario sin redo archivado, se recupera el estado de la copia consistente disponible.
- **S25 · B y D.** Aumentar tamaño y retención ayuda a conservar versiones. `RETENTION GUARANTEE` protege el undo no expirado.
- **S26 · A.** `V$RECOVERY_AREA_USAGE` desglosa el uso de la FRA por tipo de archivo.

## Simulacros de recuperación

| Simulacro | RTO observado | RPO observado | Evidencia |
|---|---|---|---|
| A · Caída de instancia | Tiempo total no registrado | 0 cambios confirmados perdidos en las filas de control | 14a. La fila 102 conservó EGRESADO y la 103 quedó en ACTIVO. |
| B · Pérdida de control file | Tiempo total no registrado | Sin pérdida observada al restaurar una copia multiplexada | 14b. Oracle abrió con las tres copias y la PDB en READ WRITE. |
| C · Borrado con PURGE | 171 s de restauración | 1 s entre la copia y el fallo | 14c. Se recuperaron 60.000 matrículas. |
| D · Pérdida de datafile | 9 s desde el fallo, 8 s durante la reparación del archivo | 0 en la transacción de control | 14d. La fila 104 conservó EGRESADO después de RECOVER. |

## Retrospectiva

**Simulacros de recuperación.** El alert log permitió identificar el control file ausente en B y comprobar que Oracle había cerrado FREEPDB1 en D. La restauración completa recuperó las 60.000 matrículas en C. En D, RMAN aplicó el redo posterior a la copia y conservó el cambio confirmado. En una próxima ejecución mediré A y B desde la interrupción hasta que vuelva a responder una consulta funcional en la PDB.

**FRA llena (caso del enunciado).** Las cargas repetidas agotaron la cuota de la FRA. El aviso ORA-19815 precedió a las esperas `log file switch (archiving needed)`. Se recuperó espacio con RMAN en el entorno del laboratorio. Como medida preventiva, incorporaría una alerta al 80 % de ocupación y revisaría `V$RECOVERY_AREA_USAGE` antes de repetir cargas masivas.
