# Práctica 3 — Preguntas de comprobación

## 1. Diferencia entre imagen y contenedor

Una imagen es una plantilla con el software y sus dependencias. Un contenedor es una instancia creada a partir de ella. En G2 descargué la imagen de Alpine y en G4 creé un contenedor desde esa imagen para ejecutar una terminal.

## 2. Persistencia de nota.txt

En G5 el archivo estaba en la capa de escritura del contenedor y desapareció al eliminarlo. En G6 estaba dentro de un volumen: al montar ese mismo volumen en otro contenedor, el archivo seguía disponible.

## 3. docker ps y docker ps -a

docker ps muestra los contenedores en ejecución. docker ps -a incluye también los detenidos. Exited (0) significa que el proceso principal terminó correctamente, con código de salida cero.

## 4. Publicación de puertos

En -p 8181:8181, el primer número corresponde al equipo anfitrión y el segundo al contenedor. Con -p 80:8080 se accedería al puerto 80 del equipo, que enviaría el tráfico al 8080 del contenedor. En el nginx del ejercicio no funcionaría con su configuración predeterminada, porque nginx escucha en el puerto 80 interno.

## 5. Duración de los contenedores

Un contenedor permanece activo mientras su proceso principal continúa ejecutándose. Oracle presta un servicio que sigue en marcha. hello-world muestra un mensaje y termina su proceso, por lo que el contenedor se detiene.

## 6. Digest de la imagen

El digest es una identificación basada en el contenido de la imagen. La etiqueta latest puede apuntar a una versión diferente en el futuro. Registrar el digest permite identificar exactamente qué imagen se utilizó.

## 7. Eliminación de los datos de Oracle

docker rm oralab-26ai elimina el contenedor, pero conserva el volumen con nombre oralab-26ai-data. El comando docker volume rm oralab-26ai-data eliminaría ese volumen y sus datos; Docker exige que antes deje de estar asociado a un contenedor. No es un comando que deba ejecutar para entregar la práctica.

## 8. Repositorio, Issue, rama y Pull Request

Este flujo permite planificar la instalación, relacionar los cambios con una necesidad y revisar los scripts y las evidencias antes de incorporarlos a main. Además, deja un historial que permite reconstruir y comprender el entorno.

## 9. source frente a bash

source ejecuta el archivo en la terminal actual, por lo que sus variables y funciones quedan disponibles en ella. bash lo ejecuta en un proceso separado y sus cambios no se trasladan a la terminal que lo lanzó. Usamos source para reutilizar las constantes y la función ts.

## 10. Nombre de una evidencia

En 20260915T091230Z_02-docker.script.log, 20260915 es la fecha: 15 de septiembre de 2026. T separa fecha y hora; 091230 representa las 09:12:30 y Z indica UTC. El 02 identifica el paso, docker describe el contenido y .script.log señala una evidencia de terminal.

## 11. Finalidad de .gitattributes

Define cómo debe tratar Git determinados archivos. Las reglas de la práctica mantienen los finales de línea LF en los archivos .sh, .sql y .md. Evitan que los finales CRLF de Windows provoquen errores al ejecutar scripts en Linux, como bash seguido de un carácter de retorno de carro.

## 12. Create a merge commit

Esta opción conserva los commits de cada parte de la instalación y añade un commit que registra la integración de la rama. Squash and merge reuniría todos esos cambios en un único commit y perderíamos ese detalle en el historial de main.

## 13. Las cuatro capas de protección de contraseñas

Primero se configura .gitignore para excluir config/.env. Después se crea config/.env.example con valores de ejemplo. La tercera capa es el archivo local config/.env con los secretos reales y permisos restringidos. La cuarta consiste en cargar sus variables y utilizarlas sin escribir las contraseñas directamente en los comandos.

Si se omite la primera capa, un git add podría incluir accidentalmente el archivo real. Además, añadirlo después a .gitignore no elimina un secreto que ya se haya versionado.

## 14. Contraseña en docker run

Aunque el script no se publique, una contraseña escrita literalmente puede quedar en el historial de la terminal, en una captura o en un registro. Por eso el comando utiliza una variable cargada desde el archivo local. Esto evita escribir el valor real en el código, aunque no sustituye el control de acceso a Docker y al equipo.

## 15. Contraseña publicada en un commit

No basta con borrarla mediante un commit nuevo, porque seguiría en los commits anteriores. Hay que cambiar o revocar inmediatamente la contraseña expuesta y después limpiar el historial y coordinar la actualización de las copias del repositorio. Una contraseña publicada debe considerarse comprometida.

## 16. SQL*Plus dentro del contenedor

Los archivos del repositorio están en Ubuntu y SQL*Plus se ejecuta en el sistema de archivos del contenedor. Sin copiar o montar esos archivos, @archivo.sql no encuentra la ruta local y SPOOL guardaría su salida dentro del contenedor. Enviamos el SQL por la entrada estándar mediante docker exec -i y usamos tee en Ubuntu para guardar la evidencia en el repositorio.

## 17. WHENEVER SQLERROR EXIT SQL.SQLCODE

Hace que SQL*Plus termine con un código de error cuando una sentencia SQL o un bloque PL/SQL falla. Así el proceso que lo ejecuta puede detectar el fallo. Sin esta instrucción, SQL*Plus podría continuar con las siguientes sentencias y dejar una migración parcialmente aplicada.

## 18. Migraciones

Una migración es un archivo versionado que introduce un cambio en la base de datos. V000 prepara los usuarios y tablespaces; V001 crea las tablas de los negocios. Después de aplicarlas deben conservarse para que el historial refleje lo ejecutado. Los cambios posteriores se añaden en una migración nueva.

## 19. Servicio FREEPDB1

FREEPDB1 identifica la base de datos conectable donde trabajamos y donde se encuentran nuestros usuarios y tablas. FREE corresponde al servicio del contenedor raíz. Usar el servicio FREEPDB1 dirige la conexión a la PDB correcta; un SID identifica una instancia y no sustituye esa selección de servicio.

## 20. SQLcl y SQL*Plus

SQLcl ofrece funciones que facilitan el trabajo, como autocompletado, formatos de salida y gestión de conexiones. SQL*Plus es una herramienta clásica que sigue presente en servidores y scripts de administración. Un DBA debe conocer ambas para trabajar cómodamente y poder administrar entornos donde solo esté disponible SQL*Plus.

## 21. De Git Bash a Ubuntu en WSL 2

Ubuntu proporciona un entorno Linux con sus herramientas y gestor de paquetes. Git Bash puede convertir automáticamente rutas de comandos Docker, lo que causa problemas con rutas internas como /opt/oracle/oradata. También puede presentar dificultades con las terminales interactivas y docker exec -it. En Ubuntu trabajamos con rutas y terminales Linux sin esas adaptaciones de Git Bash.

## 22. Ubicación del repositorio y elección de Bash

El repositorio está en ~/oracle-database-lab para trabajar dentro del sistema de archivos de Linux. Esto mejora el rendimiento de las operaciones con muchos archivos y mantiene el comportamiento de permisos y rutas de Linux. /mnt/c sirve para acceder a Windows y copiar archivos puntuales, como las capturas.

Bash permite seguir los scripts del curso con el mismo intérprete y evita diferencias de sintaxis o expansión de zsh. El encabezado #!/usr/bin/env bash también deja explícito qué intérprete necesita cada script.
