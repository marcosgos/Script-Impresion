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
    -cups)
        ip=$(hostname -I | awk '{print $1}')
        url="http://$ip:631"
        firefox "$url" &
        ;;
    *)
        echo "Opción no válida. Usa [--help] [-i] [-d] [-s] [-c] [-r] [-p] [-u] [-cups] [-otros]"
        ;;
esac
