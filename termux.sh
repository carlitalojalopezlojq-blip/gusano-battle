#!/data/data/com.termux/files/usr/bin/bash
set -e
pkg update -y
pkg install git nodejs -y
printf '\nProyecto listo. Para compilar Android, sube este repositorio a GitHub y ejecuta Actions.\n'
printf 'Para iniciar el servidor multijugador: cd server && npm install && node server.js\n'
