#!/bin/bash
# Antes de ejecutar verificar y/o cambiar el punto de montaje [mnt][media] segun su distribucion de linux
# Si va a usar un disco formatearlo en ext3 para mayor compatibilidad
# Si va a usar unidades de red Debe tener instalado:
#    "smbfs", "samba", "samba-common" y "smbclient" o "cifs-utils" para montar carpetas compartidas
#    La carpeta compartida deve tener permisos para escritura para everyone
#
# by l.bonfante | Dic-2014

#Punto de Montaje  [Puede cambiar esta opcion]
puntomount=mnt
rutared='//172.16.0.45/InformaWEB'

#INICIO
clear
echo -e "\nANTES DE INICIAR ASEGURE QUE:"
echo -e "\n  1. Tiene suficiente espacio en el destino para realizar la copia del disco."
echo -e "\n  2. Si el destino es un disco USB: Particionelo en formato Ext3"
echo -e "\n  3. Si el destino es una unidad de red: Debe tener permisos de acceso"
echo -e "\n  4. Verifique que tiene instalados los paquetes (pdkg -l | grep cifs): cifs-utils y smbclient"
echo -e "\n  5. Si el directorio /mnt no existe: modifique el scrip LINEA 11 puntomount=NUEVODIR \n"

#Muestra info de discos conectados para identificar Origen
#	sudo df -h
	sudo fdisk -l
	read -p "Disco que se convertira a IMG (Ej. sda): " discoO

#Crea punto de Montaje para el disco de Destino (Lugar donde se guardara imagen)
	sudo mkdir /$puntomount/srvvhd
  echo -e "\nSe montara la unidad de destino del VHD en /$puntomount/srvvhd"

#Seleccion del Destino
	echo -e "\nDestino del VHD:"
	echo "    1. Disco ext3 USB (Conecte su disco ahora)"
	echo "    2. Unidad de Red usando CIFS o SMB"
	read -n1 -p "Seleccione una opcion: " Destino
	echo -e "\n"

case $Destino in
  	1 ) cd /dev/disk/by-id/; ls -l; 
        read -p "Identifique la unidad de destino [Ej. usb-Samsung342-disk0:0-part1]: " discod;    
        sudo mount /dev/disk/by-id/$discod /$puntomount/srvvhd;;
  	2 ) read -p "Ruta a unidad de Red de destino [Ej. //172.16.0.45/CarpetaComp]: " discod;
        read -p "Usuario de red para coneccion [Ej. luis]: " usuariored;
	      echo -e "Se conectara la Ruta de destino: $discod, con el usuario: $usuariored \n SE SOLICITARA CONTRASEÑA DE $usuariored: \n";
      	    sudo mount.cifs $discod /$puntomount/srvvhd -o user=$usuariored;; 
    * ) echo "ENTRADA INCORRECTA"; 
        sudo rmdir /$puntomount/srvvhd; exit 100;;
esac

#INICIAR COPIA?
	read -n1 -p "Inicia copia de disco /dev/$discoO a /$puntomount/srvvhd/disk2vhd.img [y/n]: " resp;

if [ $resp == "y" ]; then
	  #Realiza copia de disco
    echo "INICIANDO PROCESO DE COPIADO..."
	  sudo dd if=/dev/$discoO of=/$puntomount/srvvhd/disk2vhd.img
    #Informacion para usuario
  	echo "COPIA REALIZADA CORRECTAMENTE."
    echo "  En el disco de destino encontrara el archivo disk2vhd.img"
else
  	echo "OPERACION CANCELADA POR EL USUARIO."  
fi

#Desmontamos la unidad
	echo "Desmontando disco de destino..."
	umount /$puntomount/srvvhd

#Conversion de la imagen extraida en formato RAW
echo -e "\n  LA IMAGEN ESTA EN FORMATO, RAW PARA CONVERTIR A VHD:"
echo -e "    1. INSTALE qemu-utils"
echo -e "    2. VALLA AL DESTINO DONDE GUARDO LA IMAGEN disk2vhd.img"
echo -e "    3. EJECUTE: qemu-img convert -f raw -O vpc imglinux.img vhdlinux.vhd"
echo -e "  NOTA: Debe contar con espacio suficiente en el disco de destino para hacer la conversion a VHD."
echo -e "\n \n  Para convertir la imagen a otro formato remplace en el paso 3 \"vpc\" por el formato correspondiente:"
echo -e "\n  **Image format**    **Argument to qemu-img**"
echo -e "  raw                     raw"
echo -e "  qcow2                   qcow2"
echo -e "  VDI (VirtualBox)        vdi"
echo -e "  VMDK (VMWare)           vmdk"
echo -e "  VHD (Hyper-V)           vpc"
