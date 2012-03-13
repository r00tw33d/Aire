#!/bin/bash

source colors_vars.sh 
############################################################
# Descripción de la función
#
# @argumen $1 interfaz de red.
# @argumen $2 ruta del archivo temporal.
# @return tipo descripcion de lo que regresa
# @link [URL de mayor infor]
############################################################
function mostrarCeldas ()
{
    echo -e "${On_IBlack}Seleccione un objetivo${Color_Off}";
    `iwlist $1 scann 2>&1  | grep -E Cell\|Quality\|ESSID\|Channel: > $2`
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
				export q_range=`echo -e "$line" | sed 's/Quality=//'`;
				;;
			'essid')
				export essid=`echo -e "$line" | sed 's/ESSID://'`;
				export q_range='        ';
				export q_range2='        ';
				echo -e "\n${On_IRed}${cell}${Color_Off}\t${BWhite}$essid${Color_Off}"
				echo -e "\tCalidad: ${On_Blue}${q_range}${On_Green}${q_range2}${Color_Off}";
				echo -e "\t${Purple}Canal: $channel${Color_Off} ${Blue}MAC: ${mac}${Color_Off}";
				;;
		esac
	done < $2
	echo -e "\n${BCyan}Inserte el número de un objetivo [XX]: ${Color_Off}";
}

############################################################
# Descripción de la función
#
# @argumen $1 Recibe la linea.
# @return tipo descripcion de lo que regresa
# @link [URL de mayor infor]
############################################################
function _mostrarCeldasNumLinea() {
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

INTERFAZ='wlan0';
infoPath='tmp_file';

mostrarCeldas $INTERFAZ $infoPath;
