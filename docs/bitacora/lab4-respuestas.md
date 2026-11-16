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
