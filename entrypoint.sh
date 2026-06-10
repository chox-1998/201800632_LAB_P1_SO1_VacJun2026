#!/bin/bash
set -e
APP_DIR=/app
MODULE_NAME="continfo_pr1_so1_201800632"

echo "SOPES1 Proyecto 1"

echo "Instalando dependencias..."
apt-get update -qq
apt-get install -y -qq \
    build-essential \
    gcc \
    make \
    kmod \
    golang-go \
    docker.io \
    cron \
    curl \
    jq


echo "[entrypoint] Compilando módulo de kernel..."
make -C "$APP_DIR/kernel_module"


echo "[entrypoint] Cargando módulo de kernel..."
if lsmod | grep -q "$MODULE_NAME"; then
    echo "[entrypoint] Módulo ya cargado, recargando..."
    rmmod "$MODULE_NAME"
fi
insmod "$APP_DIR/kernel_module/${MODULE_NAME}.ko"

echo "[entrypoint] Verificando /proc/${MODULE_NAME}..."
cat /proc/"$MODULE_NAME" | head -5 && echo "[entrypoint] /proc OK"


echo "[entrypoint] Levantando Grafana y Valkey..."
docker compose -f "$APP_DIR/docker-compose.yml" up -d grafana valkey
echo "[entrypoint] Grafana disponible en http://localhost:3000"


echo "[entrypoint] Registrando cronjob..."
chmod +x "$APP_DIR/scripts/spawn_containers.sh"
CRON_JOB="*/2 * * * * $APP_DIR/scripts/spawn_containers.sh >> /var/log/sopes1-cron.log 2>&1"
( crontab -l 2>/dev/null | grep -v "spawn_containers"; echo "$CRON_JOB" ) | crontab -
service cron start
echo "[entrypoint] Cronjob activo (cada 2 min)."


echo "[entrypoint] Compilando daemon Go..."
cd "$APP_DIR/daemon"
go build -o /usr/local/bin/sopes1-daemon .

echo "Iniciando daemon"
exec /usr/local/bin/sopes1-daemon
