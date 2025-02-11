#!/bin/bash 

echo "impresión [--help] [-i] [-d] [-s] [-c] [-r] [-p] [-u] [-cups]" 
echo "" 
echo "[--help] Muestra la ayuda" 
echo "[-i] Instala el servicio" 
echo "[-d] Desinstala el Servicio" 
echo "[-s] Muestra el status del Servicio" 
echo "[-c] Archivo de Configuracion"
echo "[-r] Reinicia el Servicio"
echo "[-p] Cambiar el puerto"
echo "[-u] Configurar Firewall"
echo "[-cups] Abre en Firefox Cups"
echo "[-otros] Mas opciones..."
echo "y"



if [ $1 = "-otros" ]; then
    echo "Elige una Opcion:"
    echo ""
    echo "1- Generar Archivo para impresión"
    echo "2- Mostrar los archivo Impresos"
    echo "3- Conversion de PDF a WORD de los archivos impresos"
    echo "4- Recursos que esta usando Cups"
    echo "5- Copia de Seguridad en Zip"
    echo ""
fi

if [ $1 = "-i" ]; then
	sudo apt update
	sudo apt upgrade -y
	sudo apt install cups
	sudo apt install cups-pdf
	sudo usermod -a -G lpadmin $whoami
fi

if [ $1 = "-d" ]; then
	sudo systemctl stop cups
 	sudo apt-get remove --purge cups cups-daemon cups-client
	sudo apt-get autoremove --purge
	sudo rm -rf /etc/cups
 	cups-config --version
fi

if [ $1 = "-cups" ]; then
	ip=$(hostname -I | awk '{print $1}')
	url="http://$ip:631"
	firefox "$url" &
fi
