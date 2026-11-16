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
