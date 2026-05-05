OPCION A - ARCHIVOS HTML EN MINUSCULAS PARA GITHUB PAGES

Objetivo:
Evitar errores cuando el index busca panchosfit_c019771.html pero GitHub tiene PANCHOSFIT_C019771.html.
GitHub Pages distingue mayusculas/minusculas.

Forma recomendada con GitHub Desktop:
1. Descarga renombrar_html_a_minusculas.ps1.
2. Colocalo dentro de la carpeta principal del repositorio Toyo-MX.
3. Abre GitHub Desktop.
4. Menu: Repository > Open in Terminal.
5. Ejecuta:
   powershell -ExecutionPolicy Bypass -File .\renombrar_html_a_minusculas.ps1
6. Regresa a GitHub Desktop.
7. Revisa los cambios.
8. Escribe el commit: normalizar html a minusculas
9. Da clic en Commit to main.
10. Da clic en Push origin.

Despues de eso, el index deberia abrir correctamente los clientes.

Tambien se incluye un ZIP completo con index, logo, clients.json y archivos en minusculas.
