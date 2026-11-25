# 🐍 GUSANO BATTLE
Proyecto Godot 4 para Android: arcade de gusanos con control táctil, bots, minimapa pequeño inferior izquierdo, etiquetas de jugador, boost, sonidos originales y estructura de salas WebSocket.

## Incluido
- Juego offline contra bots.
- Arena compacta y cámara suave.
- Gusanos dibujados por código con ojos, brillo, sombra y nombres sobre la cabeza.
- Minimapa en esquina inferior izquierda.
- Joystick táctil y acelerador.
- HUD, ranking, puntuación, pantalla de carga, muerte y reinicio.
- WAV originales generados para efectos y ambiente.
- Servidor WebSocket Node.js de salas en `server/`.
- Workflow de GitHub Actions para exportar APK debug.

## Abrir en Godot
Instala Godot 4.3+ (se recomienda 4.4/4.5), abre `project.godot`, ejecuta con F6/F5. El juego está configurado para orientación horizontal.

## Termux + GitHub
1. En Termux instala Git: `pkg install git -y`.
2. Clona tu repositorio: `git clone https://github.com/TU-USUARIO/gusano-battle.git`.
3. Sube el proyecto a GitHub y activa Actions.
4. Workflow `Android APK` compila el APK debug y lo deja como artefacto descargable en cada ejecución.

## Multijugador
El servidor incluido en `server/` permite crear/unirse a salas y enviar inputs. Para conexión desde celulares fuera de la misma red, debes alojarlo en una máquina/hosting accesible, preferiblemente con HTTPS/WSS. El juego offline funciona sin servidor. El cliente de esta primera entrega contiene la conexión y envío de inputs; el render/sincronización remota se seguirá afinando en las siguientes revisiones.

## Rendimiento
Renderizado 2D, sin shaders pesados ni modelos 3D, arena limitada, draw calls simples, control vectorial y cámara interpolada. Objetivo: 60 FPS en dispositivos compatibles, con 30 FPS estables en equipos más modestos.

## Nota de la versión
Esta entrega es la base funcional del juego: el modo local, controles, mapa, HUD, audio y servidor de salas están incluidos. El modo online sincroniza movimiento, nombres, tamaño y comida; la colisión/respawn del servidor es básica y todavía requiere una prueba real con dos teléfonos y ajuste de latencia antes de publicarlo como juego comercial.

## Subir a tu GitHub desde Termux
Crea primero un repositorio vacío llamado `gusano-battle` en tu cuenta. Desde la carpeta del proyecto ejecuta:

```bash
pkg install git -y
bash upload_github.sh
```
GitHub te solicitará autenticación (usa token o el método de login que tengas configurado; tu contraseña normal no se acepta para `git push`).
