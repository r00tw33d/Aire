# --------------------------------------------------------- #
# descarga e instala el aire
#
# @param     : $1 la ruta donde se va a instalar
# @return    : susses
# @author    : fitorec <fitorec@hacer-laptop>
# @link      : http://gnu.org
# --------------------------------------------------------- #
function installAire() {
	export aire_dst=$1
	if [ "${aire_dst}" = "" ]
	then
		export aire_dst=${HOME}/.config/
	fi
	echo "ruta de instalacion ${aire_dst}";
	#descargamos el aire en el directorio temporal
	wget https://github.com/r00tw33d/Aire/tarball/master -O /tmp/aire.tar.gz
	tar xvfz /tmp/aire.tar.gz -C ${aire_dst}
	rename 's/\*/aire/' "${aire_dst}/r00tw33d-Aire*"
	
	cat ${HOME}/.bashrc | grep -qE 'alias\s+aire='

	if [ $? -ne 0 ]
	then
		echo "alias aire='${aire_dst}/aire.sh'" >> ${HOME}/.bashrc
	fi
}


wget https://github.com/r00tw33d/Aire/tarball/master -O aire.tar.gz
tar xvfz aire.tar.gz
rename 's/\*/aire/' r00tw33d-Aire*

echo 'pendiente por favor ejecute: ';
echo 'sudo ./aire/aire.sh';
exit 0;

installAire
