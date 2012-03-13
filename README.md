Audiotoria de redes
==========================================================================================

_Aire_ es un conjunto de scripts elaborado para facilitar la auditoria de redes inalambricas.
Su fin es `semi-automatizar` el crackeo de **WEP** keys (únicamente **WEP**, no **WPA**) con una poca interveción del usuario.
Fue desarrollado con fines puramente educativos ;)

#Advertencias y recomendaciones:

 - Lxs colaboradorxs de este proyecto no se hacen responsables por el mal uso ke se le pueda dar.
 - Este proyecto está echo con fines educativos. Por favor, se conciente si lo utilizas ;) **¡Robar Wi-Fi es ilegal!**.
 - Come frutas y verduras!.

#Uso e intalación:

###Requerimientos:

 - macchanger
 - aircrack-ng

`sudo apt-get install macchanger aircrack-ng`

#Desarrolladores

Para unirte solo ingresa al _github_ realiza un fork y empuja solicitud de cambios, este [r00tw33d](https://github.com/r00tw33d) se encargara de revisarlas.

###Estructura actual:

Actualmente el _aire_ esta en proceso de convertirse en un conjunto de scripts, lo cual nos ha remplanteado la estructura del proyecto, la cual la tenemos definida como sigue:

	.
	|-- aire.sh
	|-- README.md
	`-- src
		|-- colors_vars.sh
		|-- locale
		|   |-- en
		|   |   `-- aire_msg.po
		|   `-- es
		|       `-- aire_msg.po
		`-- stdOutFunctions.sh


###Colaboradores

- [r00tw33d](https://github.com/r00tw33d)
- [fitorec](https://github.com/fitorec)
