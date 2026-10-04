# Laboratorio 1 — Preguntas de comprobación

Name: Beatriz Lopez
Professor: Richard Aviles Lopez

## 1. ¿Cuál es la diferencia entre Working Directory, Staging Area y Local Repository? Da un ejemplo de un archivo pasando por las tres.

El Working Directory es la carpeta donde trabajo y modifico los archivos.

La Staging Area es la zona donde preparo los cambios que quiero incluir en el siguiente commit. Los añado con git add.

El Local Repository guarda el historial de commits en mi ordenador, dentro de la carpeta .git.

Por ejemplo, al escribir README.md, modifiqué un archivo del Working Directory. Con git add README.md preparé su contenido en la Staging Area. Después, con git commit, guardé esa versión en el Local Repository.

## 2. Si modificas un archivo pero no haces git add, ¿aparece ese cambio en tu próximo commit? Explica por qué.

No, si utilizo git commit sin opciones adicionales. El commit solo guarda los cambios preparados en la Staging Area.

Además, si modifico un archivo después de hacer git add, tengo que añadirlo otra vez para incluir las últimas modificaciones.

## 3. ¿Por qué git status no mostraba las carpetas vacías que creaste en la Parte C? ¿Qué truco usamos para solucionarlo?

Git registra archivos, no carpetas vacías. Por eso esas carpetas no aparecían en git status.

Para conservarlas, creamos dentro archivos llamados .gitkeep. Es una convención: ese nombre no tiene una función especial en Git. Al añadir y confirmar esos archivos, sus carpetas quedan representadas en el repositorio.

## 4. Explica con tus propias palabras qué es HEAD.

HEAD indica dónde estoy trabajando en el historial de Git. Normalmente apunta a la rama actual, y esa rama apunta a su último commit.

Por ejemplo, cuando estaba en feature/customer-search, HEAD señalaba esa rama. Al cambiar a main, HEAD pasó a señalar main.

## 5. ¿Qué diferencia hay entre crear una branch con git switch -c y crear una carpeta nueva con mkdir? ¿Cómo lo comprobamos en la Parte G?

mkdir crea una carpeta física en el ordenador.

git switch -c crea una rama de Git y me cambia a ella. Una rama permite desarrollar cambios con su propio historial, pero no crea otra carpeta del proyecto.

En la parte G comprobé que crear feature/customer-search no creaba una carpeta llamada feature. También observé que customer-search.md desaparecía al cambiar a main y reaparecía al volver a feature/customer-search, porque estaba confirmado solamente en esa rama.

## 6. Durante el conflicto de la Parte H, ¿qué representaba el contenido entre <<<<<<< HEAD y =======? ¿Y entre ======= y >>>>>>>?

Entre <<<<<<< HEAD y ======= estaba la versión de la rama actual, main, que contenía el título Training Edition.

Entre ======= y >>>>>>> estaba la versión de la rama que intentaba fusionar, fix/readme-subtitle, con el título Academic Version.

Para resolverlo, combiné los dos títulos y eliminé los marcadores. Después hice git add README.md y un commit para completar el merge.

## 7. ¿Por qué NO se debe hacer git commit --amend sobre un commit que ya se subió con git push?

Porque --amend sustituye el último commit por uno nuevo con un hash diferente. Esto modifica el historial.

Si otra persona ya descargó el commit original, su historial y el mío pueden dejar de coincidir. Por eso, cuando el commit ya está compartido, lo habitual es corregirlo mediante un nuevo commit.

## 8. Si borras por accidente la carpeta .git de tu proyecto, ¿qué se pierde exactamente? ¿Se pierde también el código fuente que está en el disco?

Se pierde la información local de Git: el historial de commits, las ramas, la Staging Area y la configuración del repositorio, incluidos sus remotos.

Los archivos del proyecto que están fuera de .git permanecen en el disco, pero esa carpeta deja de funcionar como repositorio Git.

Si existe una copia en GitHub, puedo recuperar lo que se haya subido clonando el repositorio. Los commits exclusivamente locales no estarían en esa copia.

## 9. Explica con tus propias palabras la diferencia entre Git y GitHub, sin usar la palabra "nube".

Git es un programa que permite controlar versiones, guardar commits, crear ramas y fusionar cambios. Puedo utilizarlo en mi ordenador sin conexión a Internet.

GitHub es una plataforma web donde puedo alojar repositorios Git y colaborar con otras personas. También ofrece herramientas como Pull Requests, Issues y revisión de código.

## 10. ¿Por qué no se debe subir un archivo .env con contraseñas reales a un repositorio, aunque el repositorio sea privado?

Porque las personas y herramientas con acceso al repositorio podrían leer esas contraseñas. Además, podrían quedar guardadas en el historial aunque después borrara el archivo.

Lo adecuado es excluir .env mediante .gitignore y utilizar un archivo .env.example con valores ficticios para explicar la configuración necesaria.

Si una contraseña se sube por accidente, hay que cambiarla o revocarla; borrar el archivo no basta.

## 11. Un compañero te dice: "hice push y ahora GitHub me rechaza el segundo push con non-fast-forward". ¿Qué ha ocurrido probablemente y qué comando ejecutarías primero?

Probablemente el repositorio remoto tiene nuevos commits que todavía no están en su ordenador. Otra persona pudo subir cambios, o él mismo pudo editar un archivo desde GitHub.

Primero comprobaría el estado con git status. Si no hay cambios locales pendientes, ejecutaría git pull para traer e integrar los cambios remotos. Si aparecieran conflictos, los resolvería antes de volver a hacer git push.

## 12. ¿Qué tipo de Conventional Commit usarías para añadir un índice de rendimiento a una tabla, corregir una restricción mal definida y actualizar el README?

Para añadir un índice cuyo objetivo sea mejorar el rendimiento, usaría perf:

perf(db): add index to improve customer searches

Para corregir una restricción mal definida, usaría fix:

fix(db): correct customer constraint

Para actualizar el README, usaría docs:

docs: update project README