#!/bin/bash

printf '																								\n'
printf '   		   _  _    _____                 _    _______  _            ______  _               	\n'
printf '		 _| || |_ |  __ \               | |  |__   __|| |          |  ____|| |                  \n'
printf '		|_  __  _|| |__) |  ___    ___  | |_    | |   | |__    ___ | |__   | |  __ _   __ _     \n'
printf '		 _| || |_ |  _  /  / _ \  / _ \ | __|   | |   |  _ \  / _ \|  __|  | | / _` | / _` |    \n'
printf '		|_  __  _|| | \ \ | (_) || (_) || |_    | |   | | | ||  __/| |     | || (_| || (_| |    \n'
printf '		  |_||_|  |_|  \_\ \___/  \___/  \__|   |_|   |_| |_| \___||_|     |_| \__,_| \__, |    \n'
printf '		****************************************************************************** __/ |    \n'
printf '		******************************************************************************|___/ 	\n'
printf '																								\n\n'

# Códigos de color
YELLOW='\033[1;33m'
GREEN='\033[1;32m'  # Color verde
NC='\033[0m'        # Sin color

detener_y_eliminar() {
    docker ps -aq --filter "name=${1}_container" | xargs -r docker stop >/dev/null 2>&1
    docker ps -aq --filter "name=${1}_container" | xargs -r docker rm >/dev/null 2>&1
    docker images -q "$1" | xargs -r docker rmi -f >/dev/null 2>&1
}

# Función para manejar la señal INT
handle_int() {
    printf "\r\033[K"  # Limpia la línea actual
    stty -echo  # Desactivar el eco
    printf 'La maquina se esta eliminando...\n'
    detener_y_eliminar "$IMAGE_NAME"
    printf "${GREEN}La maquina se ha eliminado de manera exitosa.\n${NC}\n"
    stty echo  # Reactivar el eco
    exit 0
}

trap handle_int INT

if [ $# -ne 1 ]; then
    echo "Uso: $0 <archivo_tar>"
    exit 1
fi

if ! command -v docker &>/dev/null; then
    echo "Docker no esta instalado. Iniciando la instalacion de Docker..."
    sudo apt update >/dev/null 2>&1
    sudo apt install -y docker.io >/dev/null 2>&1
    sudo systemctl restart docker >/dev/null 2>&1
    sudo systemctl enable docker >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Error instalando Docker."
        exit 1
    fi
fi

TAR_FILE="$1"
IMAGE_NAME="${TAR_FILE%.tar}"

detener_y_eliminar "$IMAGE_NAME"

# Mensaje inicial
printf "Se esta cargando la imagen de Docker...\r"

docker load -i "$TAR_FILE" >/dev/null
if [ $? -ne 0 ]; then
    echo "Ha ocurrido un error al cargar la imagen de Docker."
    exit 1
fi

# Limpiar la línea
printf "\033[K"

#Fix aportado por https://github.com/DanielDominguezBender/ para Dockerlabs
if uname -m | grep -q 'arm'; then 
    sudo apt install -y binfmt-support qemu-user-static >/dev/null
    docker run --platform linux/amd64 -d --name "${IMAGE_NAME}_container" "$IMAGE_NAME" >/dev/null
else
    docker run -d --name "${IMAGE_NAME}_container" "$IMAGE_NAME" >/dev/null
fi

IP_ADDRESS=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${IMAGE_NAME}_container")

# Mensaje de éxito con IP
printf "La maquina se ha desplegado con exito.\n"
printf "Dirección IP asignada: ${YELLOW}$IP_ADDRESS${NC}\n\n"
printf "Presiona Ctrl+C para detener y eliminar la maquina.\n\n"

while :; do sleep 1; done

# Cuando la imitación supera al original... @ElBarbas_IT
