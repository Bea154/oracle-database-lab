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

## Diagnóstico y correcciones — Parte C

Los cinco datafiles de negocio estaban dentro del volumen, pero en
una carpeta no estándar. La ruta dbs era un enlace simbólico hacia
/opt/oracle/oradata/dbconfig/FREE/dbs.
Evidencia: 20261116T193715Z_01-diagnostico-inicial.script.log.

Los reubicamos en /opt/oracle/oradata/FREE/FREEPDB1/.
Primero se pone el tablespace OFFLINE, después se copia el archivo
y se actualiza su ruta en Oracle con RENAME DATAFILE.
RENAME DATAFILE no mueve físicamente el archivo.
Cada datafile quedó con crecimiento automático y un máximo de 1 GB.
Al repetir el script respondió "Nada que reubicar".

V003 convirtió los cinco propietarios en cuentas de solo esquema:
conservan sus objetos, pero tienen AUTHENTICATION_TYPE = NONE.
El intento de conexión de admin_academia fue rechazado con ORA-01017.
No modificamos V000 ni V001 porque son migraciones ya aplicadas.

La prueba de persistencia recreó el contenedor conservando el volumen.
Antes y después había 14 tablas y 0 estudiantes.
El nuevo contenedor publica únicamente el puerto 1521.
Esta prueba comprueba la persistencia del volumen; no es una
restauración de la copia de seguridad.

Después aplicamos V002: 20000 estudiantes, 40 asignaturas y
60000 matrículas. El estudiante 101 tiene estado ACTIVO.

## Instancia y base de datos — Parte D

Me conecté como C##OPS_RO al servicio free, en CDB$ROOT.
La cuenta permite observar el catálogo sin utilizar SYSDBA.

Tres datos de la instancia:
- Nombre: FREE.
- Estado: OPEN.
- Arranque: 2026-11-16 19:52:40.

Tres datos de la base:
- DBID: 1509902213.
- Modo de archivado: ARCHIVELOG.
- Modo de apertura: READ WRITE.

La consulta SQL mostró 16 datafiles, 3 tempfiles, 3 miembros
de redo y 2 control files.

Desde Linux observé 61 procesos de background y un consumo del
contenedor de 2.109 GiB. Esta cifra no equivale solo a la SGA.
No se deben sumar los RSS, porque incluyen memoria compartida.

Evidencias: archivos terminados en _05-instancia-y-base.spool.log
y _05-instancia-so.script.log.

## Arranque por etapas — Parte E

En NOMOUNT existe la instancia: Oracle ha leído el SPFILE,
reservado la SGA y arrancado los procesos. v$instance muestra
STARTED, pero v$database devuelve ORA-01507 porque la base
todavía no está montada.

En MOUNT Oracle ha abierto los control files y conoce los
16 datafiles. La base aún no está abierta: consultar dba_tables
devuelve ORA-01219 porque requiere acceder al diccionario
almacenado en los datafiles.

En OPEN la base queda READ WRITE y la instancia OPEN/ACTIVE.
FREEPDB1 se abrió automáticamente en READ WRITE porque tenía
guardado el estado OPEN mediante SAVE STATE.

El alert log confirma la parada completa, el montaje y la apertura.
Aparecieron avisos ORA-00800 con Set Priority Failed para VKTM
y LGWR. En esta ejecución no impidieron abrir la base.
No apareció ORA-20013 en el extracto revisado.

Evidencias: registros terminados en
_06-arranque-por-etapas.script.log y _06-alert-log.script.log.

## Parámetros — Parte F

v$parameter muestra los valores efectivos de la sesión actual.
v$spparameter muestra los ajustes guardados en el SPFILE.

Con open_cursors, SCOPE=MEMORY dejó 400 en memoria y 300 en SPFILE.
SCOPE=BOTH dejó 500 en ambos. Después lo restauramos a 300.
Al arrancar con SPFILE, el SCOPE predeterminado de ALTER SYSTEM
SET es BOTH, siempre que el parámetro admita ese cambio.

db_files rechazó el cambio en memoria con ORA-02095.
Con SCOPE=SPFILE quedó 200 en memoria y 300 en SPFILE.
RESET eliminó el ajuste persistente; en memoria siguió en 200.

Aunque processes aparecía como IMMEDIATE, el intento de cambiarlo
en memoria fue rechazado con ORA-02097 y ORA-02095.
memory_size devolvió ORA-62352 porque no estaba configurado
al arrancar la instancia.

En FREEPDB1 pudimos cambiar open_cursors, pero cambiar processes
devolvió ORA-65040. Después eliminamos el ajuste local y verificamos
open_cursors = 300 tanto en la raíz como en FREEPDB1.

Creamos PFILE desde SPFILE (32 líneas) y desde memoria (122 líneas).
Versionar estas copias permite comparar la configuración y detectar
deriva de configuración: diferencias respecto al estado previsto.

Evidencias: _07-parametros-lectura.spool.log,
_07-parametros-cambios.script.log, _07-verificacion-final.script.log
y config/initFREE_lab4*.ora.

## Memoria y caché — Parte G

La instancia usa ASMM: memory_target = 0, sga_target = 1536M
y pga_aggregate_target = 512M. Oracle gestiona automáticamente
el reparto de la SGA y gestiona la PGA por separado.
db_cache_size = 0 y shared_pool_size = 0 no significan áreas
vacías, sino que no fijamos mínimos explícitos para ellas.

En el experimento de caché ambas rondas devolvieron 17600 activos:
- Fría: 380 lecturas lógicas y 265 físicas.
- Caliente: 247 lecturas lógicas y 0 físicas.
La segunda ejecución siguió leyendo bloques, pero desde memoria.
Al final había 245 bloques de ACA_ESTUDIANTES en caché.
La tasa orientativa de acierto fue 30.3% y 100%, respectivamente.

En 1000 consultas con literales hubo 1008 análisis duros y
620 ms de tiempo total. Con variable de enlace hubo 1 análisis
duro, un cursor reutilizado 1000 veces y 10 ms de tiempo total.

La ordenación automática de 60000 matrículas fue OPTIMAL:
2314 KiB usados, sin TEMP y 40 ms.
Con el área limitada a 64 KiB necesitó 6 pasadas y 2048 KiB
en TEMP; tardó 270 ms.

El resumen acumulado de áreas de trabajo de la instancia mostró
4576 ejecuciones óptimas, 0 de una pasada y 2 de varias pasadas.
Estas cifras no corresponden únicamente al experimento.

Evidencias: _08-memoria.spool.log,
_08-experimento-cache.script.log y _08-parse-y-pga.script.log.

## Procesos — Parte H

LGWR mostró SPID 1811 en Oracle, coincidente con el PID 1811
observado dentro del contenedor mediante /proc.
Linux mostró 104 MB de RSS para ese proceso. El RSS incluye
memoria compartida y no equivale a memoria privada del proceso.

docker top puede mostrar otro PID porque usa el espacio de
identificadores del host; Oracle utiliza el del contenedor.

LGWR escribe el redo necesario para confirmar las transacciones.
DBWn escribe los bloques modificados a los datafiles.

PMON detecta procesos terminados y participa en su limpieza,
por ejemplo cuando un proceso servidor termina inesperadamente.
SMON participa en la recuperación de instancia, por ejemplo
tras una caída sin cierre limpio.

Hay 4 procesos ARCn, coherente con el modo ARCHIVELOG.
Archivan el redo de los grupos llenos.

Evidencias: _09-procesos.spool.log y _09-procesos-so.script.log.

## Contenedores, diccionario y archivos — Apartados 10 y 11

PDB_LAB4 se creó desde PDB$SEED, pasó de MOUNTED a READ WRITE
y después se cerró y eliminó con sus datafiles.
Los errores ORA-65096, ORA-65094 y ORA-65025 fueron esperados.
La prueba de visibilidad terminó con 0 usuarios LAB4 restantes.

Desde CDB$ROOT, DBA_TABLESPACES mostró 5 tablespaces.
CDB_TABLESPACES mostró 15: 5 de la raíz y 10 de FREEPDB1.

Concedimos SELECT sobre SYS.V_$DIAG_ALERT_EXT a C##OPS_RO.
La cuenta pudo leer el alert log sin recibir permisos de escritura.

El ADR ocupa 32 MB y contiene 249 trazas en esta medición.
Está fuera del volumen, en la capa del contenedor: sus registros
se pierden al eliminar el contenedor.
El bloque de SPFILE/password file de la inspección Linux salió
vacío; esto no demuestra que falten esos archivos.

Evidencias: registros de los apartados 10 y 11 en script/ y spool/.

## Bloque y dirección física — Apartado 12

El estudiante 101, con estado ACTIVO, estaba en el archivo 16
(academia01.dbf), bloque 780, posición 5.
El DATA_OBJECT_ID de ACA_ESTUDIANTES era 73125.

El volcado mostró una fila de 78 bytes y 7 columnas.
La columna ESTADO ocupaba 6 bytes: 41 43 54 49 56 4f,
que representan ACTIVO. La traza completa se guardó en
20261117T062947Z_12-volcado-bloque.trc.txt, con 5682 líneas.

El ROWID permite localizar físicamente una fila, pero puede cambiar
al reorganizarla; no sustituye a su clave primaria.

## Capacidad y coste de lectura — Apartado 13

ACA_ESTUDIANTES tenía 20000 filas, longitud media de 76 bytes
y bloques de 8192 bytes, con PCTFREE 10.
Había 231 bloques con filas, con una media de 86.6 filas por bloque.
Las estadísticas mostraron 244 bloques bajo la HWM y el segmento
tenía 256 bloques asignados.

La fórmula de la Unidad 3 estimó 95 filas por bloque y 211 bloques.
La aproximación con sobrecarga Oracle estimó 93 y 216.
Las estimaciones no reflejan toda la distribución y gestión real
del espacio.

El banco de pruebas contenía 400000 filas.
Las búsquedas en caché hicieron 400000 lecturas lógicas y
consumieron 760 ms de CPU.
La prueba aleatoria hizo 5464 lecturas físicas en 115.7 ms.
El recorrido completo leyó 4595 bloques en 53 peticiones y 22 ms.

Estas medidas pertenecen al entorno del laboratorio.
Vaciar el Buffer Cache de Oracle no vacía la caché de Linux;
por ello no equivalen a medir directamente la velocidad del disco.

## Migración y encadenamiento — Apartado 14

MIGRA comenzó con 5000 filas y CHAIN_CNT = 0.
Al ampliar una de cada cinco filas, CHAIN_CNT pasó a 1000:
el 20% había migrado. La lista de filas afectadas confirmó 1000.

En 1000 búsquedas hubo 200 accesos a filas continuadas
y 3200 lecturas lógicas, una media de 3.2 por búsqueda.
El volcado mostró un puntero nrid hacia la nueva ubicación.

ANCHA contenía dos filas y CHAIN_CNT = 1: la fila de unos
12000 bytes necesitaba varios bloques de 8 KiB.
Esto es encadenamiento; moverla no hace que quepa en un bloque.

ALTER TABLE MOVE reorganizó MIGRA con PCTFREE 20.
El índice PK_MIGRA quedó UNUSABLE y después de REBUILD volvió
a VALID. CHAIN_CNT quedó en 0.

Se eliminó el banco de pruebas. TBS_LAB4_RESTANTES = 0.

## Informe y verificación — Apartados 15 y 16

Se ejecutó el informe de diagnóstico con C##OPS_RO.
La verificación final terminó sin fallos, según el resultado
observado. Esto comprueba los controles del script, pero no
sustituye la revisión de las respuestas ni de la entrega en GitHub.

Evidencias de los apartados 12 a 16: registros en script/, spool/
y el volcado conservado en config/.

## Detalle del bloque para las preguntas 26 y 27

En el bloque 780: nrow = 90; fsbo = 0xc6 = 198;
fseo = 0x427 = 1063; avsp = 0x361 = 865 bytes.
Se cumple avsp = fseo - fsbo = 1063 - 198 = 865.

La entrada ITL muestra Lck = 90 y Flag --U-: información de una
transacción confirmada pendiente de completar la limpieza del
bloque. No demuestra 90 bloqueos activos actuales.
La limpieza diferida actualiza esa información al acceder después
al bloque.
Evidencia: 20261117T062947Z_12-volcado-bloque.trc.txt.

# Preguntas de comprobación — Respuestas numeradas

## 1. Consistencia de la copia
SHUTDOWN IMMEDIATE deshace las transacciones sin confirmar,
escribe los cambios pendientes y cierra limpiamente la base.
Durante la copia los archivos no cambian. Copiarlos directamente
con la base abierta no garantiza consistencia.
Evidencia: 20261116T192550Z_00-backup-lab3.script.log,
"ORACLE instance shut down" antes de copiar el volumen.

## 2. Manifiesto y SHA256SUMS
manifiesto.txt identifica la copia: fecha, imagen, contenedor,
volumen, commit y tipo de copia. SHA256SUMS contiene las huellas
para detectar cambios o daños en sus archivos.
restaurar-estado.sh verifica las sumas antes de modificar el entorno.
Mi comprobación dio OK para todos los archivos.
Evidencia: 20261116T193010Z_00-verificacion-backup.script.log.

## 3. RPO y RTO
RPO es la pérdida de datos tolerable, expresada como tiempo.
Si solo dispongo de mi copia lab3-final, los cambios posteriores
a ese punto no están protegidos por ella.
RTO es el tiempo objetivo para recuperar el servicio.
Mi copia ocupa 544 MB, pero todavía no he medido una restauración:
no puedo afirmar un RTO probado ni deducirlo del tamaño.
La recreación del contenedor no fue una restauración del backup.
Evidencia: copia 20261116T192551Z_lab3-final y registro 00-backup.

## 4. Ubicación de los datafiles de V000
V000 utilizaba nombres relativos, como academia01.dbf.
Oracle los creó bajo ORACLE_HOME/dbs. En mi imagen, dbs es
un enlace a /opt/oracle/oradata/dbconfig/FREE/dbs:
persistían en el volumen, pero en una carpeta no estándar.
Una ruta absoluta adecuada habría evitado esa ubicación.
DB_CREATE_FILE_DEST permite configurar un destino OMF cuando
se crean archivos sin especificar un nombre de archivo explícito.
Evidencia: 20261116T193715Z_01-diagnostico-inicial.script.log.

## 5. RENAME DATAFILE no mueve el archivo
Solo cambia la ruta registrada por Oracle. Por eso pusimos
el tablespace OFFLINE, copiamos físicamente el archivo,
actualizamos la ruta y lo devolvimos a ONLINE.
El original se eliminó después del éxito de esos pasos.
Evidencia: 20261116T193930Z_03-reubicar-datafiles.script.log.

## 6. V003 e invalidación de contraseñas
No modificamos V000 porque ya se aplicó: usamos V003 para
registrar una corrección nueva y trazable.
Borrar una contraseña del archivo no la elimina del historial.
NO AUTHENTICATION impide seguir utilizándola y conserva
los objetos del propietario del esquema.
Evidencia: salida de V003, AUTHENTICATION_TYPE = NONE para
los cinco ADMIN_*, y conexión rechazada con ORA-01017.

## 7. Prueba de persistencia
Demuestra que el contenedor puede reemplazarse conservando
los objetos en el volumen. Antes y después había 14 tablas
y 0 estudiantes; V002 se aplicó posteriormente.
Se hace después de reubicar para no depender de archivos
que pudieran quedar en la capa eliminable del contenedor.
Evidencia: 20261116T195258Z_03-prueba-persistencia.script.log.

## 8. Instancia frente a base de datos
Instancia: nombre FREE, estado OPEN y arranque
2026-11-16 19:52:40 en la primera medición.
Base: DBID 1509902213, modo ARCHIVELOG y 16 datafiles.
Al reiniciar cambió la hora de arranque, pero el DBID permaneció.
Evidencias: registros 05-instancia-y-base y 15-autopsia-instancia.

## 9. NOMOUNT, MOUNT y OPEN
NOMOUNT lee los parámetros y crea la memoria y los procesos.
v$instance funciona, pero v$database devuelve ORA-01507.
MOUNT abre los control files y conoce los 16 datafiles;
dba_tables devuelve ORA-01219 porque la base no está abierta.
OPEN abre los datafiles y redo logs y permite acceder a la base.
Evidencia: 20261116T201139Z_06-arranque-por-etapas.script.log.

## 10. v$parameter frente a v$spparameter
v$parameter muestra el valor efectivo para la sesión.
v$spparameter muestra los ajustes persistentes del SPFILE.
Con db_files vimos 200 en memoria y 300 en SPFILE:
el cambio persistente todavía no se había aplicado al arrancar.
RESET quitó ese ajuste y dejó el valor actual en 200.
Evidencia: 20261116T201840Z_07-parametros-cambios.script.log.

## 11. PROCESSES e IMMEDIATE
Aunque v$parameter mostraba IMMEDIATE, el intento de cambiar
PROCESSES en memoria fue rechazado con ORA-02097 y ORA-02095.
La propiedad mostrada no bastó para garantizar ese cambio:
la restricción efectiva del parámetro exige configurarlo para
un próximo arranque. No interpretamos IMMEDIATE como permiso
para aplicar cualquier valor en cualquier circunstancia.
Evidencia: _07-parametros-cambios.script.log.

## 12. Modelo de memoria
La instancia usa ASMM: MEMORY_TARGET = 0, SGA_TARGET = 1536M
y PGA_AGGREGATE_TARGET = 512M.
Oracle reparte automáticamente la SGA y gestiona por separado
la PGA. MEMORY_SIZE también era 0.
Evidencia: _08-memoria.spool.log, bloque 1.

## 13. Experimento de caché
La ronda fría hizo 380 lecturas lógicas y 265 físicas.
La caliente hizo 247 lógicas y 0 físicas.
Ambas devolvieron 17600 estudiantes activos.
La tasa orientativa 100*(1-físicas/lógicas) fue 30.3% y 100%.
La segunda consulta siguió accediendo a bloques, pero los
encontró en memoria. Al final había 245 bloques en caché.
Evidencia: _08-experimento-cache.script.log.

## 14. Literales frente a variables de enlace
Con literales hubo 1048 análisis totales, 1008 duros y 620 ms.
Con :id hubo 1 análisis total, 1 duro y 10 ms.
V$SQL mostró un cursor con bind ejecutado 1000 veces,
con 39 KiB en shared pool. Para literales mostró 652 cursores
y 23944 KiB en esa medición.
Los contadores de parse incluyen trabajo interno y V$SQL
muestra lo que permanece en caché, no necesariamente todo
el historial de consultas ejecutadas.
Reutilizar el mismo texto con valores enlazados redujo el trabajo.
Evidencia: _08-parse-y-pga.script.log.

## 15. SPID de LGWR y PID de Linux
LGWR mostró SPID 1811 y el script que consultó /proc dentro
del contenedor mostró PID 1811.
docker top puede mostrar otro número porque utiliza el espacio
de PID del host; Oracle utiliza el del contenedor.
Evidencias: _09-procesos.spool.log y _09-procesos-so.script.log.

## 16. Datafiles desde la raíz y desde FREEPDB1
Desde la raíz, SYS puede consultar los archivos de la CDB:
4 de CDB$ROOT, 3 de PDB$SEED y 9 de FREEPDB1, total 16.
Dentro de FREEPDB1 la consulta queda limitada a esa PDB:
sus 9 datafiles, incluidos los cinco de negocio.
Cambiar de contenedor cambia el ámbito de la misma vista.
Evidencia: _11-archivos.spool.log, inventario por contenedor;
contrastar con _10-que-ve-cada-usuario.script.log.

## 17. ORA-00942 para LAB4_ANALISTA
CREATE SESSION permite conectarse, pero no concede acceso
a DBA_TABLES ni a las tablas de otros esquemas.
ORA-00942 significa que el objeto no existe o no es accesible
para esa sesión; no demuestra que la vista esté ausente.
Evidencia: _10-que-ve-cada-usuario.script.log, bloque 3.

## 18. C##LAB4_AUDITOR frente a C##OPS_RO
Ambos reciben permisos de catálogo y cambio de contenedor.
C##OPS_RO tiene además CONTAINER_DATA = ALL.
Ese atributo permite ampliar la visibilidad entre contenedores
de las vistas que lo utilizan, sin conceder escritura.
Para igualar ese aspecto de visibilidad, desde CDB$ROOT:
ALTER USER c##lab4_auditor SET CONTAINER_DATA = ALL
  CONTAINER = CURRENT;
Esto no iguala otros permisos adicionales, como el SELECT
sobre V_$DIAG_ALERT_EXT concedido después a C##OPS_RO.
Evidencia: _10-que-ve-cada-usuario.script.log, bloques 5 y 6.

## 19. Permiso READ a nivel de esquema
GRANT READ ANY TABLE ON SCHEMA admin_academia permite
dar lectura a las tablas del esquema, incluidas las futuras,
sin conceder permisos tabla por tabla.
Reduce mantenimiento, pero amplía el acceso: una tabla futura
con datos sensibles también quedaría incluida.
No permite UPDATE ni acceso a otros esquemas.
Evidencia: _10-que-ve-cada-usuario.script.log, bloque 4.

## 20. COMMON_USER_PREFIX
El valor observado fue C##.
Crear lab4_local desde la raíz produjo ORA-65096 porque
el nombre de un usuario común debía comenzar por ese prefijo.
Crear ese usuario local dentro de FREEPDB1 sí fue válido.
Evidencia: _10-ciclo-vida-pdb.script.log, bloque 3.

## 21. Archivos de la base y relacionados
La base incluye datafiles, control files y redo online.
Los tempfiles almacenan trabajo temporal y se pueden recrear.
Son archivos relacionados el SPFILE, password file, redo
archivado y los registros y trazas del ADR.

El password file está relacionado con la administración:
permite autenticar conexiones administrativas, pero no guarda
las tablas de negocio. En mi entorno su ruta registrada es
/opt/oracle/product/26ai/dbhomeFree/dbs/orapwFREE.
La carpeta dbs enlaza con almacenamiento del volumen.
Evidencias: _11-archivos.spool.log y diagnóstico 01.

## 22. Tamaño de academia01.dbf
Oracle informa 100 MiB: 100*1024*1024 = 104857600 bytes.
Linux muestra 104865792 bytes.
La diferencia es 8192 bytes, un bloque adicional de cabecera
del archivo que no entra en el tamaño informado por esa vista.
Evidencia: _11-archivos-so.script.log y _11-archivos.spool.log.

## 23. Puntos únicos de fallo
Los dos control files están en el mismo volumen: perder ese
almacenamiento puede afectar a ambos, aunque haya dos archivos.
Cada grupo de redo tiene un solo miembro: no hay una segunda
copia del miembro dentro del grupo.
Los tres grupos no son copias entre sí; contienen tramos
distintos de redo.
Acción propuesta: redundancia en almacenamiento independiente
y copias con recuperación probada.
Evidencia: _11-archivos.spool.log, rutas y grupos de redo.

## 24. ADR fuera del volumen
La base puede conservar sus datos mientras se pierden el
alert log y las trazas al eliminar el contenedor.
Esto dificulta investigar incidentes y reconstruir lo ocurrido.
En mi medición el ADR ocupaba 32 MB y contenía 249 trazas.
Evidencia: _11-archivos-so.script.log, bloques 3 y 4.

## 25. ROWID del estudiante 101
DBMS_ROWID identificó DATA_OBJECT_ID = 73125,
archivo absoluto 16, bloque 780 y posición de fila 5.
El archivo 16 corresponde a academia01.dbf y el objeto 73125
a ADMIN_ACADEMIA.ACA_ESTUDIANTES.
Se usó ROWID_OBJECT, ROWID_TO_ABSOLUTE_FNO,
ROWID_BLOCK_NUMBER con BIGFILE y ROWID_ROW_NUMBER.
Evidencia: _12-bloque.script.log, bloque 4.

## 26. Espacio libre del bloque
nrow = 90 indica las entradas de fila del bloque.
fsbo = 0xc6 = 198 es el inicio del espacio libre.
fseo = 0x427 = 1063 es su final.
avsp = 0x361 = 865 bytes de espacio disponible.
Se cumple avsp = fseo - fsbo = 1063 - 198 = 865.
Evidencia: 20261117T062947Z_12-volcado-bloque.trc.txt.

## 27. ITL y limpieza diferida
La entrada ITL muestra Lck = 90 y Flag --U-.
Conserva información de una transacción confirmada cuya
limpieza del bloque todavía no está completada.
No significa que existan ahora 90 bloqueos activos.
La limpieza diferida actualiza la información transaccional
del bloque cuando se accede a él posteriormente.
Evidencia: cabecera ITL del volcado 12.

## 28. Los 78 bytes de la fila 101
Los datos de sus siete columnas ocupan:
3 + 9 + 9 + 11 + 19 + 6 + 11 = 68 bytes.
Se añaden 7 bytes de longitud, uno por columna en esta fila,
y 3 bytes de cabecera de fila.
Total: 68 + 7 + 3 = 78 bytes, coincidente con tl: 78.
La entrada del directorio de filas es adicional y no forma
parte de esos 78 bytes.
Evidencia: volcado 12, "LA FILA 5", longitudes de col 0 a col 6.

## 29. Factor de bloqueo y número de bloques
Con B = 8192, cabecera = 96, PCTFREE = 10 y R = 76:
bfr = floor((8192-96)*0.9/76) = 95 filas por bloque.
b = ceil(20000/95) = 211 bloques.

La aproximación Oracle del script incorpora 122 bytes de
cabecera y 2 bytes por entrada de directorio:
bfr = floor((8192-122)*0.9/(76+2)) = 93;
b = ceil(20000/93) = 216.

Las estadísticas reales dieron 244 bloques bajo la HWM.
Hay distribución no uniforme, espacio reservado y estructuras
de gestión que la fórmula simplificada no reproduce totalmente.
El recuento encontró 231 bloques con filas, media de 86.6 filas.
Evidencia: _13-capacidad.script.log, bloques 1 a 3.

## 30. Coste de las lecturas
Lógica: 760 ms de CPU / 400000 lecturas = 1.9 microsegundos
de CPU por lectura.
Física aleatoria: 115.7 ms / 5464 = aproximadamente
21.2 microsegundos por bloque, incluyendo trabajo de CPU.
Secuencial: 22 ms / 4595 = aproximadamente
4.79 microsegundos por bloque.
Son medidas de naturaleza distinta: CPU para la primera
y tiempo transcurrido para las otras dos.
No equivalen a latencias puras del dispositivo físico.
Evidencia: _13-capacidad.script.log, bloques 5a a 5c.

## 31. Umbral de rentabilidad con HDD
Usamos el banco de pruebas: 400000 filas y 4676 bloques.
Su factor de bloqueo aproximado es round(400000/4676) = 86.

Con transferencia de 150 MiB/s y latencia aleatoria de 5 ms:
coste secuencial por bloque =
8192/(150*1048576) = 0.00005208 s.
Cociente secuencial/aleatorio =
0.00005208/0.005 = 0.0104167.

El umbral aproximado es:
k/r < (1/86)*0.0104167 = 0.0001211,
es decir, aproximadamente 0.0121% de las filas.
En este modelo simplificado, por encima de ese umbral el
recorrido completo resulta más barato que los accesos aleatorios.
Si MB se interpreta en base decimal, resulta aproximadamente
0.0127%; hay que mantener las unidades coherentes.
Evidencia: _13-capacidad.script.log y supuestos de la pregunta.

## 32. Lecturas físicas en microsegundos
FLUSH BUFFER_CACHE vacía la caché de Oracle, pero no la caché
de páginas de Linux. Una lectura física para Oracle puede
resolverse desde memoria del sistema operativo.
Esto no invalida la medición del entorno, pero impide presentar
sus tiempos como latencias puras del disco.
Evidencia: _13-capacidad.script.log, advertencia tras el bloque 5.

## 33. Migración y encadenamiento
Migración: una fila crece y no cabe en su bloque original,
aunque sí pueda caber completa en otro. Se mueve y deja
un puntero desde su ubicación original.
Encadenamiento: la fila requiere varias piezas; en el ejemplo,
unos 12000 bytes no caben en un bloque de 8 KiB.

Se detectaron con ANALYZE, CHAIN_CNT, LIST CHAINED ROWS
y el contador table fetch continued row.
CHAIN_CNT por sí solo no distingue ambas causas.
Reorganizar eliminó la migración de MIGRA, pero no haría
caber la fila de ANCHA en un bloque de 8 KiB.
Para el encadenamiento del ejemplo se debe valorar rediseño
o un tamaño de bloque mayor compatible con el entorno.
Evidencia: _14-filas-migradas.script.log.

## 34. Las 3.2 lecturas lógicas por búsqueda
En 1000 búsquedas, 200 accedieron a filas migradas: el 20%.
Con un coste base de unas 3 lecturas por búsqueda y una
lectura adicional para cada fila migrada:
3 + 0.20*1 = 3.2.
Coincide con 3200 lecturas lógicas y 200 accesos continuados.
Evidencia: _14-filas-migradas.script.log, bloque 4.

## 35. MOVE e índice UNUSABLE
MOVE reorganiza el segmento y cambia los ROWID de las filas.
El índice anterior conserva referencias a las ubicaciones viejas,
por eso este MOVE lo dejó UNUSABLE.
ALTER INDEX PK_MIGRA REBUILD lo devolvió a VALID.
En producción planificaría disponibilidad, espacio y recuperación;
valoraría MOVE ONLINE y mantenimiento de índices si la edición,
versión y características de la tabla lo permiten.
Evidencia: _14-filas-migradas.script.log, bloque 7.

## 36. Tres hallazgos de la autopsia
1. Control files en el mismo volumen y un miembro por grupo
de redo. Riesgo de pérdida conjunta o de un miembro sin copia.
Acción: redundancia independiente y recuperación probada.
Prioridad alta para producción.

2. ALTURA_MAX vacía en cuatro esquemas. Riesgo de estadísticas
ausentes o incompletas. Acción: comprobar LAST_ANALYZED
y recoger estadísticas donde corresponda. Prioridad media.

3. Cuatro mensajes ORA en 24 horas. Riesgo de ignorar incidentes
o confundir experimentos con fallos. Acción: clasificarlos
por contexto. ORA-65025 fue una prueba intencionada;
ORA-959 se registró en DROP TABLESPACE IF EXISTS preventivo;
los ORA-00800 se revisan por sus argumentos. Prioridad media.

Evidencia y desarrollo: docs/bitacora/lab4-autopsia.md,
_15-autopsia-instancia.spool.log y _15-contexto-ora959.script.log.

## 37. C##OPS_RO frente a SYSTEM
C##OPS_RO permite observar con los permisos necesarios:
catálogo, cambio de contenedor, visibilidad CONTAINER_DATA
y lectura explícita del alert log.
No recibe permisos para modificar las tablas de negocio,
crear usuarios ni parar o arrancar la instancia.
SYSTEM tiene privilegios administrativos mucho más amplios.
Usar mínimo privilegio reduce el impacto de un error al consultar.
Evidencias: creación de la cuenta 02 y ampliación de permiso 11.

## 38. Dos vías de exposición corregidas
Primera: las contraseñas literales de los propietarios de esquema
en V000 y su historial. V003 las invalidó con NO AUTHENTICATION
sin borrar las tablas ni modificar la migración aplicada.

Segunda: la contraseña de SYS en los argumentos del comando
de aplicación de migraciones, visible en herramientas de procesos
y potencialmente en registros de ejecución.
La versión corregida usa autenticación del sistema operativo:
sqlplus / as sysdba dentro del contenedor.
Evidencias: V003 y scripts/deployment/env/08-aplicar-migraciones.sh.
