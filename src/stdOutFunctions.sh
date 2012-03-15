#!/bin/bash
# Utilerias para administrar la salida estandar
#
# @author: fitorec
# @Description: Utilerias para administrar la salida estandar
# @link http://r00tw33d.github.com/Aire

############################################################
# Imprime un mensaje traducido, a partir de las variables
# previamente configuradas:  AIRE_BASE_PATH y AIRE_LANG
#
# @argumen $1 Printf format
# @argumen $2 El mensaje a traducir
# @return tipo descripcion de lo que regresa
# @link http://r00tw33d.github.com/Aire
############################################################
function locate() {
	local result=''
	local msg_file="${AIRE_BASE_PATH}/src/locale/${AIRE_LANG}/aire_msg.po";
	local line_msgid=`cat $msg_file | grep -En --color "^msgid\s+\"$2\"$" | cut -d: -f1`;

	if [ "$?" -eq 0 ]; then
		local next_line_msgid=`expr ${line_msgid} + 1`;
		result=`cat ${msg_file} | head -${next_line_msgid} | tail -1 | grep -Eo '".*"' | sed -r 's/^.(.*)./\1/'`
	fi
	if [ "${result}" = "" ]; then
		printf "${1}" "$2"
		return 1;
	fi
	printf "${1}" "${result}"
	return 0;
}

############################################################
# Enlista los objetivos y pregunta por uno de ellos
#
# @argumen $1 interfaz de red.
# @argumen $2 ruta del archivo temporal.
# @link http://en.wikipedia.org/wiki/ANSI_escape_code
############################################################
function mostrarObjetivos () {
	local cell='';
    local mac='';
    local channel='';
    local quality='';
    local essid='';

	locate "${On_IBlack}%s $1${Color_Off}" "Revisando targeta";
    iwlist $1 scann 2>&1 | grep -E Cell\|Quality\|ESSID\|Channel: > $2
    if [ $? -gt 1 ]
	then
		case "$?" in
			"254")
				locate "\n${On_IRed}%s ${$1}${Color_Off}" "Levantando targeta de red"
				ifconfig $1 up
				mostrarObjetivos $1 $2
				return 0;
				;;
			 "*")
				locate "\n${On_IRed}%s iwlist $1 scann 2>&1${Color_Off}" "Error desconocido al ejecutar:";
				exit 1;
				;;
		esac
	fi
	initDisplay
    locate "${On_IBlack}%s${Color_Off}" "Seleccione un objetivo";
    while read line
	do
		local tipoDeLinea=`echo "${line}" | grep -Eo Cell\|Quality\|ESSID\|Channel`
		case "$tipoDeLinea" in
			'Cell')
				cell=`echo -e "$line" | grep  -oiE '^Cell\s[0-9]+' | sed 's/Cell\s//'`;
				mac=`echo -e "$line" | grep  -oiE '[0-f:]+$'`;
				;;
			'Channel')
				channel=`echo -e "$line" | sed 's/Channel://'`;
				;;
			'Quality')
				range=`echo -e "$line" | grep -oE '[0-9]+\/[0-9]+'`;
				val_quality_range=`echo -e "$range" | cut -d/ -f1`;
				val_quality=`echo -e "$range" | cut -d/ -f2`;
				val_quality_diff=`expr $val_quality_range - $val_quality`;
				#Generamos una secuencia de espacios
				printf -v style_quality "%${val_quality_range}s" ' '
				printf -v style_quality_diff "%${val_quality_diff}s" ' '
				;;
			'ESSID')
				essid=`echo -e "$line" | sed 's/ESSID://'`;
				echo -e "\n${On_IRed}${cell}${Color_Off}\tESSID:${BWhite}$essid${Color_Off}"
				locate "\n\t%s ${On_Blue}${style_quality}${On_Green}${style_quality_diff}${Color_Off}" "Calidad:";
				locate "\n\t${Purple}%s $channel${Color_Off} ${Blue}MAC: ${mac}${Color_Off}" "Canal:";
				;;
		esac
	done < $2
	locate "\n${BCyan}%s [XX]:${Color_Off}" "Inserte el número de un objetivo"
}

############################################################
# Selecciona una interfaz de red que soporte 802.11,
# de haber mas de una, las muestras en un menu  como opciones
#
# @link http://r00tw33d.github.com/Aire
############################################################
function select_interface() {
	local NUM_INTERFACES=`iwconfig 2>&1 | grep 802.11 | grep -v 'Mode:Monitor' | wc -l`

	if [ "$NUM_INTERFACES" -gt 1 ]; then
		locate "${White}%s"  "Especifike un número de la lista:"
		select INTERFAZ in `iwconfig 2>&1 | grep 802.11 | grep -v 'Mode:Monitor' | grep -oE "^\w*"`; do
			if [ $INTERFAZ ]; then
				break;
			else
				clear
				locate "${Red}%s${Color_Off}${White}" "Especifike una interfaz valida:"
			fi
		done #end select
	else
		INTERFAZ=`iwconfig 2>&1 | grep 802.11 | grep -oE "^\w*" | head -1`
	fi
	echo -e ${Color_Off}
}
############################################################
# Imprime en el inicio un logo de Aire de forma aletaoria
#
# @link http://r00tw33d.github.com/Aire
############################################################
function initDisplay() {
	clear
	local template=`ls "${AIRE_BASE_PATH}/src/init_displays/" | sort -R | head -1`
	echo -e "${Cyan}\c";
	cat "${AIRE_BASE_PATH}/src/init_displays/${template}";
	echo -e  "${Color_Off}";
}
