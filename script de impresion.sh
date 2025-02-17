#!/bin/bash 

case $1 in
    --help)
        echo "impresión [--help] [-i] [-d] [-s] [-c] [-r] [-p] [-u] [-cups] [-otros]" 
        echo "" 
        echo "[--help] Muestra la ayuda" 
        echo "[-i] Instala el servicio" 
        echo "[-d] Desinstala el Servicio" 
        echo "[-s] Muestra el estado del Servicio" 
        echo "[-c] Archivo de Configuración"
        echo "[-r] Reinicia el Servicio"
        echo "[-p] Cambiar el puerto"
        echo "[-u] Configurar Firewall"
        echo "[-cups] Abre en Firefox CUPS"
        echo "[-otros] Más opciones..."
        echo ""
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
                echo "Funcionalidad no implementada"
                ;;
            2) 
                ls -l "$HOME/pdf"
                ;;
            3) 
                echo "Archivo convertido (Funcionalidad no implementada)"
                ;;
            4) 
                top -p "$(pgrep -d',' cups)"
                ;;
            5) 
                sudo cp /etc/cups/cupsd.conf "$HOME/Escritorio/cupsd.conf.backup"
                zip "$HOME/Escritorio/cupsd_backup.zip" "$HOME/Escritorio/cupsd.conf.backup"
                ;;
            *) 
                echo "Opción no válida, elige un número entre 1 y 5"
                ;;
        esac
        ;;
    -i)  
        sudo apt update
        sudo apt upgrade -y
        sudo apt install -y cups cups-pdf
        sudo usermod -a -G lpadmin "$USER"
        ;;
    -d)  
        sudo systemctl stop cups
        sudo apt-get remove --purge -y cups cups-daemon cups-client
        sudo apt-get autoremove --purge -y
        sudo rm -rf /etc/cups
        ;;
    -s)  
        sudo systemctl status cups
        ;;
    -c)  
        sudo nano /etc/cups/cupsd.conf
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
            1) sudo systemctl restart cups ;;
            2) sudo systemctl stop cups ;;
            3) sudo systemctl start cups ;;
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
