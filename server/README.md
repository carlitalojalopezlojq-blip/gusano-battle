# Servidor online de GUSANO BATTLE

Servidor WebSocket de salas (máximo 8 jugadores) para el prototipo. El cliente Godot necesita conectarse a una URL `ws://` o `wss://` accesible desde ambos móviles.

## Ejecutar en Termux

```bash
pkg update -y
pkg install nodejs -y
cd server
npm install
node server.js
```

El servidor escucha el puerto 8080. Para jugar entre redes distintas, necesitas exponer el servidor a internet (VPS, túnel seguro o hosting compatible). **No compartas tu IP pública sin proteger el servidor**; usa TLS (`wss://`) para un despliegue real.

Health check: `http://HOST:8080/health`

## Protocolo
- `create`: crear sala privada
- `join`: unirse con código
- `input`: dirección y boost
- `state`: estado sincronizado de sala
