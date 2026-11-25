#!/data/data/com.termux/files/usr/bin/bash
set -e
REPO="https://github.com/carlitalojalopezlojq-blip/gusano-battle.git"
git init -b main
git add .
git commit -m "Gusano Battle Android game"
git remote add origin "$REPO" 2>/dev/null || git remote set-url origin "$REPO"
git push -u origin main
