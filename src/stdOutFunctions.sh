#!/bin/bash
#Se encarga de administrar la salida estandar.

############################################################
# Enlista los objetivos y pregunta por uno de ellos
#
# @argumen $1 interfaz de red.
# @argumen $2 ruta del archivo temporal.
# @link http://en.wikipedia.org/wiki/ANSI_escape_code
############################################################

function mostrarObjetivos () {
	echo "revisando targeta $1"
    iwlist $1 scann 2>&1 | grep -E Cell\|Quality\|ESSID\|Channel: > $2
    if [ $? -gt 1 ]
	then
		case "$?" in
			"254")
				echo -e "\n${On_IRed}Levantando targeta de red ${$1}${Color_Off}"
				ifconfig $1 up
				mostrarObjetivos $1 $2
				return 0;
				;;
			 "*")
				echo -e "\n${On_IRed}Error desconocido al ejecutar iwlist $1 scann 2>&1${Color_Off}"
				exit 1;
				;;
		esac
	fi
	limpiar
    echo -e "${On_IBlack}Seleccione un objetivo${Color_Off}";
    export cell='';
    export mac='';
    export channel='';
    export quality='';
    export essid='';
    
    while read line
	do
		tipoDeLinea=`_mostrarCeldasNumLinea "${line}"`
		case "$tipoDeLinea" in
			'cell')
				export cell=`echo -e "$line" | grep  -oiE '^Cell\s[0-9]+' | sed 's/Cell\s//'`;
				export mac=`echo -e "$line" | grep  -oiE '[0-f:]+$'`;
				;;
			'channel')
				export channel=`echo -e "$line" | sed 's/Channel://'`;
				;;
			'quality')
				range=`echo -e "$line" | grep -oE '[0-9]+\/[0-9]+'`;
				val_quality_range=`echo -e "$range" | cut -d/ -f1`;
				val_quality=`echo -e "$range" | cut -d/ -f2`;
				val_quality_diff=`expr $val_quality_range - $val_quality`;
				#Generamos una secuencia de espacios
				printf -v style_quality "%${val_quality_range}s" ' '
				printf -v style_quality_diff "%${val_quality_diff}s" ' '
				;;
			'essid')
				export essid=`echo -e "$line" | sed 's/ESSID://'`;
				echo -e "\n${On_IRed}${cell}${Color_Off}\tESSID:${BWhite}$essid${Color_Off}"
				echo -e "\tCalidad: ${On_Blue}${style_quality}${On_Green}${style_quality_diff}${Color_Off}";
				echo -e "\t${Purple}Canal: $channel${Color_Off} ${Blue}MAC: ${mac}${Color_Off}";
				;;
		esac
	done < $2
	echo -e "\n${BCyan}Inserte el número de un objetivo [XX]: ${Color_Off}";
}

############################################################
# Regresa un str que indica el tipo de linea que le fue pasado
#
# @argumen $1 Recibe la linea.
# @return regresa cell/channel/quality/essid segun la linea recibida
############################################################
function _mostrarCeldasNumLinea()
{
	##Case firts line, example:
	#Cell 01 - Address: AA:BB:CC:DD:FF:00
	   echo -e "$line" | grep  -qE '^Cell\s+'
	   if [ $? -eq 0 ];
		then
			echo 'cell';
        fi
	##Case second line, example:
	#Channel:7
	   echo -e "$line" | grep  -qE '^Channel:'
	   if [ $? -eq 0 ];
		then
			echo 'channel';
        fi
	##Case three line, example:
	#Quality=26/70  Signal level=-84 dBm
	   echo -e "$line" | grep  -qE '^Quality'
	   if [ $? -eq 0 ];
		then
			echo 'quality';
        fi
	##Case four line
	#ESSID:"myNetWorking"
	   echo -e "$line" | grep  -qE '^ESSID:'
	   if [ $? -eq 0 ];
		then
			echo 'essid';
        fi
}

############################################################
# Selecciona una interfaz de red que soporte 802.11,
# de haber mas de una, las muestras en un menu  como opciones
#
# @link [URL de mayor infor]
############################################################
function select_interface() {
	local NUM_INTERFACES=`iwconfig 2>&1 | grep 802.11 | grep -v 'Mode:Monitor' | wc -l`
	if [ "$NUM_INTERFACES" -gt 1 ]; then
		echo -e "${white}Especifike un número de la lista:"
		select INTERFAZ in `iwconfig 2>&1 | grep 802.11 | grep -v 'Mode:Monitor' | grep -oE "^\w*"`; do
			if [ $INTERFAZ ]; then
				break;
			else
				clear
				echo -e "${red}Especifike una interfaz valida:${END}${white}"
			fi
		done #end select
	else
		INTERFAZ=`iwconfig 2>&1 | grep 802.11 | grep -oE "^\w*" | head -1`
	fi
	echo -e ${END}
}

############################################################
# Limpia la pantalla y setea las variables a utilizar
#
# @return void
############################################################
function limpiar()
{
	clear
}
