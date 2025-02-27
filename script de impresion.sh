#!/bin/bash 

case $1 in
    --help)
        echo "Nombre de la máquina: $(hostname) - IP: $(hostname -I | awk '{print $1}')"
        echo ""
        echo "Parametros: [--help] [-i] [-d] [-s] [-c] [-r] [-p] [-u] [-l] [-cups] [-otros]" 
        echo "" 
        echo "[--help] Muestra la ayuda" 
        echo "[-i] Instala el servicio" 
        echo "[-d] Desinstala el Servicio" 
        echo "[-s] Muestra el estado del Servicio" 
        echo "[-c] Archivo de Configuración"
        echo "[-r] Reinicia el Servicio"
        echo "[-p] Cambiar el puerto"
        echo "[-u] Configurar Firewall"
        echo "[-l] Consultar logs del servicio"
        echo "[-cups] Abre en Firefox CUPS"
        echo "[-otros] Más opciones..."
        echo ""
        ;;
    -i)
        echo "Elige una opción:"
        echo ""
        echo "1- Instalar CUPS local"
        echo "2- Instalar CUPS docker"
        echo "3- Instalar CUPS ansible"
        echo ""
        read -r opcion
        case $opcion in
            1) 
                servicio="cups"
                if systemctl is-active --quiet "$servicio"; then
                    echo "El servicio $servicio ya está instalado y activo."
                else
                    echo "El servicio $servicio no está instalado o no está activo. Procediendo con la instalación..."
                    sudo apt update
                    sudo apt upgrade -y
                    sudo apt install -y cups cups-pdf
                    sudo usermod -a -G lpadmin "$USER"
                    echo "El servicio $servicio ha sido instalado y está activo."
                fi
                ;;
            2)
                CONTAINER_NAME="cups-server"
                IMAGE_NAME="custom-cups"

                if ! command -v docker &> /dev/null; then
                    sudo apt update && sudo apt install -y docker.io
                    sudo systemctl start docker
                    sudo systemctl enable docker
                fi

                cat <<EOF > Dockerfile
                FROM ubuntu:latest
                RUN apt-get update && apt-get install -y cups && \
                    usermod -aG lpadmin root && \
                    mkdir -p /var/run/cups && \
                    chmod -R 777 /var/run/cups
                COPY cupsd.conf /etc/cups/cupsd.conf
                EXPOSE 631
                CMD ["/usr/sbin/cupsd", "-f"]
EOF

                cat <<EOF > cupsd.conf
                LogLevel warn
                Listen 0.0.0.0:631
                Browsing On
                DefaultAuthType Basic
                WebInterface Yes
EOF

                docker build -t $IMAGE_NAME .

                if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
                    docker rm -f $CONTAINER_NAME
                fi

                docker run -d --name $CONTAINER_NAME -p 631:631 --privileged $IMAGE_NAME

                rm -f Dockerfile cupsd.conf

                echo "CUPS ha sido instalado y está corriendo en el puerto 631."
                ;;
            3)
                if ! command -v ansible &> /dev/null
                then
                    echo "Instalando Ansible..."
                    sudo apt update
                    sudo apt install -y ansible
                else
                    echo "Ansible ya está instalado."
                fi

                mkdir -p ansible-cups

                echo "Escribe la IP de la máquina en la que quieras instalar el servicio: "
                read ip
                echo "Escribe el nombre del usuario: "
                read nombre
                echo "Escribe la contraseña del usuario: "
                read -s pass  # Oculta la contraseña mientras se escribe

                archivo="ansible-cups/host"
                echo "[webservers]" > $archivo
                echo "$ip ansible_ssh_user=$nombre ansible_ssh_pass=$pass" >> $archivo

                cat <<EOF > ansible-cups/cups.yml
                ---
                - name: Instalar y Configurar CUPS
                hosts: webservers
                become: yes

                tasks:
                    - name: Instalar CUPS
                    apt:
                        name: cups
                        state: present
                        update_cache: yes

                    - name: Habilitar y Arrancar el Servicio de CUPS
                    systemd:
                        name: cups
                        state: started
                        enabled: yes

                    - name: Configurar CUPS ip
                    lineinfile:
                        path: /etc/cups/cupsd.conf
                        line: "Listen 0.0.0.0:631"
                        insertafter: "^#Listen localhost:631"

                    - name: Reiniciar CUPS
                    service:
                        name: cups
                        state: restarted

                    - name: Permitir puerto 631
                    ufw:
                        rule: allow
                        port: 631
                        proto: tcp
EOF

                echo "Ejecutando el playbook de Ansible..."
                ansible-playbook -i ansible-cups/host ansible-cups/cups.yml --ask-become-pass
                ;;
                
             *) echo "Opción no válida, elige entre 1, 2 o 3" ;;
        esac
        ;;
    -d)
        servicio="cups"
        
        if ! find / -name cupsd.conf 2>/dev/null | grep -q "cupsd.conf"; then
            echo "El servicio $servicio no está instalado. No hay nada que desinstalar."
            exit 1
        fi
        
        echo "Deteniendo el servicio CUPS..."
        sudo systemctl stop cups
        
        echo "Eliminando paquetes de CUPS..."
        sudo apt-get remove --purge -y cups cups-daemon cups-client
        
        echo "Eliminando dependencias innecesarias..."
        sudo apt-get autoremove --purge -y
        
        echo "Eliminando archivos de configuración de CUPS..."
        sudo rm -rf /etc/cups
        
        echo "CUPS ha sido completamente eliminado."
        ;;

    -s) 
        servicio="cups"
        if systemctl list-units --type=service | grep -q "$servicio.service"; then
            sudo systemctl status "$servicio"
        else
            echo "El servicio $servicio no esta instalado, Primero instalalo con [-i]."
        fi
        ;;
    -c)  
        archivo="/etc/cups/cupsd.conf"
        if [ -f "$archivo" ]; then
                sudo nano "$archivo"
        else
                echo "El archivo $archivo no existe. Primero instala el Servicio [-i]"
        fi
        ;;
    -r)
        echo "Elige una opción:"
        echo ""
        echo "1- Reiniciar el servicio"
        echo "2- Parar el Servicio"
        echo "3- Encender el Servicio"
        echo ""
        read -r opcion
        case $opcion in
            1) 
                servicio="cups"
                if systemctl list-units --type=service | grep -q "$servicio.service"; then
                sudo systemctl restart cups 
                echo "El servicio se esta reiniciando..."
                else
                    echo "El servicio $servicio no esta instalado, Primero instalalo con [-i]."
                fi
                ;;

            2) 
                servicio="cups"
                if systemctl list-units --type=service | grep -q "$servicio.service"; then
                sudo systemctl stop cups 
                echo "El servicio se a parado..."
                else
                    echo "El servicio $servicio no esta instalado, Primero instalalo con [-i]."
                fi
                ;;

            3) 
                servicio="cups"
                if systemctl list-units --type=service | grep -q "$servicio.service"; then
                sudo systemctl start cups 
                echo "El servicio se esta iniciando..."
                else
                    echo "El servicio $servicio no esta instalado, Primero instalalo con [-i]."
                fi
                ;;

            *) echo "Opción no válida, elige entre 1, 2 o 3" ;;
        esac
        ;;
    -p)  
        archivo="/etc/cups/cupsd.conf"

        if [ ! -f "$archivo" ]; then
            echo "No se puede configurar el puerto. Primero instala el Servicio con [-i]."
            exit 1
        fi
        puerto_actual=$(grep -E "^[Pp]ort [0-9]+" "$archivo" | awk '{print $2}')
        if [[ -z "$puerto_actual" ]]; then
            puerto_actual=$(grep -E "^Listen localhost:[0-9]+" "$archivo" | awk -F':' '{print $2}')
        fi
        if [[ -z "$puerto_actual" ]]; then
            echo "No se pudo detectar el puerto actual. Usando el predeterminado (631)."
            puerto_actual=631
        fi
        echo "Introduce el nuevo puerto para CUPS (actualmente en el $puerto_actual):"
        read -r nuevo_puerto
        if [[ ! $nuevo_puerto =~ ^[0-9]+$ ]]; then
            echo "Error: El puerto debe ser un número."
            exit 1
        fi
        if grep -qE "^[Pp]ort [0-9]+" "$archivo"; then
            sudo sed -i "s/^[Pp]ort [0-9]\+/Port $nuevo_puerto/" "$archivo"
        elif grep -qE "^Listen localhost:[0-9]+" "$archivo"; then
            sudo sed -i "s/^Listen localhost:[0-9]\+/Listen localhost:$nuevo_puerto/" "$archivo"
        else
            echo "No se encontró una línea de 'Port' o 'Listen'. Añadiendo 'Port $nuevo_puerto' al final."
            echo "Port $nuevo_puerto" | sudo tee -a "$archivo"
        fi
        sudo systemctl restart cups
        echo "El puerto de CUPS ha sido cambiado a $nuevo_puerto"
        ;;
    -u)
        archivo="/etc/cups/cupsd.conf"

        if [ ! -f "$archivo" ]; then
            echo "No se puede configurar el Firewall. Primero instala el Servicio con [-i]."
            exit 1
        fi
        puerto_actual=$(grep -E "^[Pp]ort [0-9]+" "$archivo" | awk '{print $2}')
        if [[ -z "$puerto_actual" ]]; then
            puerto_actual=$(grep -E "^Listen localhost:[0-9]+" "$archivo" | awk -F':' '{print $2}')
        fi
        if [[ -z "$puerto_actual" ]]; then
            echo "No se pudo detectar el puerto actual. Usando el predeterminado (631)."
            puerto_actual=631
        fi
        sudo ufw allow "$puerto_actual"
        sudo systemctl restart cups
        echo "El firewall ha sido configurado para permitir el puerto $puerto_actual."
        ;;
    -l)
        echo "Elige una opción:"
        echo ""
        echo "1- Ordenar logs por fecha"
        echo "2- Logs a tiempo real"
        echo "3- Ver logs de error"
        echo ""
        read -r opcion
        case $opcion in
            1)
                journalctl -u cups --reverse
                ;;
            2)
                journalctl -u cups -f
                ;;
            3)
                journalctl -u cups | grep "error"
                ;;
            *) echo "Opción no válida, elige entre 1, 2 o 3" ;;
        esac
        ;;

    -cups)
        archivo="/etc/cups/cupsd.conf"

        if [ ! -f "$archivo" ]; then
                echo "Cups no se puede abrir en el Navegador. Primero instala el Servicio con [-i]."
                exit 1
        fi
         puerto_actual=$(grep -E "^[Pp]ort [0-9]+" "$archivo" | awk '{print $2}')
        if [[ -z "$puerto_actual" ]]; then
                puerto_actual=$(grep -E "^Listen localhost:[0-9]+" "$archivo" | awk -F':' '{print $2}')
        fi
        if [[ -z "$puerto_actual" ]]; then
                echo "No se pudo detectar el puerto actual. Usando el predeterminado (631)."
                puerto_actual=631
        fi
        url="http://localhost:"$puerto_actual
        firefox "$url" &
        ;;
    -otros)
        echo "Elige una Opción:"
        echo ""
        echo "1- Generar Archivo para impresión"
        echo "2- Mostrar los archivos impresos"
        echo "3- Conversión de PDF a WORD de los archivos impresos"
        echo "4- Recursos que está usando Cups"
        echo "5- Copia de Seguridad en Zip"
        echo ""
        read -r test
        case $test in
            1) 
                servicio="cups"
                if systemctl list-units --type=service | grep -q "$servicio.service"; then
                echo "¿Qué contenido deseas meter dentro del archivo?"
                read contenido
                ruta_archivo="$HOME/prueba_impresion.txt"
                echo "$contenido" > "$ruta_archivo"
                echo "El archivo se ha guardado exitosamente en: $ruta_archivo"
                else
                    echo "El servicio $servicio no esta instalado, Primero instalalo con [-i]."
                fi
                ;;
            2) 
                servicio="cups"
                if systemctl list-units --type=service | grep -q "$servicio.service"; then
                ls -l "$HOME/pdf"
                else
                    echo "El servicio $servicio no esta instalado, Primero instalalo con [-i]."
                fi
                ;;
            3) 
                echo "Aqui no hay nada, esto no esta echo."
                ;;
            4) 
                servicio="cups"
                if systemctl list-units --type=service | grep -q "$servicio.service"; then
                top -p "$(pgrep -d',' cups)"
                else
                    echo "El servicio $servicio no esta instalado, Primero instalalo con [-i]."
                fi
                ;;
            5) 
                servicio="cups"
                if systemctl list-units --type=service | grep -q "$servicio.service"; then
                sudo cp /etc/cups/cupsd.conf "$HOME/Escritorio/cupsd.conf.backup"
                zip "$HOME/Escritorio/cupsd_backup.zip" "$HOME/Escritorio/cupsd.conf.backup"
                else
                    echo "El servicio $servicio no esta instalado, Primero instalalo con [-i]."
                fi
                ;;
            *) 
                echo "Opción no válida, elige un número entre 1 y 5"
                ;;
        esac
        ;;
    *)
        echo "Despues del comando Usa [--help] [-i] [-d] [-s] [-c] [-r] [-p] [-u] [-cups] [-otros]"
        ;;
esac
