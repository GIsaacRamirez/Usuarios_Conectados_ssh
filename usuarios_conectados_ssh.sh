#!/bin/bash

typeset -i cont #valor para colorear
typeset -i NumArray
typeset -i numAnterior
declare -a array
declare -a arrayAux
declare -a arrayDesconectados
cont=0

#grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' expresionregular de ip
#guardar los datos en memoria
#last obtiene la informacion de todas las conexiones
#al pasar el pipeline siguiente grep -E expresionregular de ip mostramos la ip
# con grep -v 0.0.0.0 excluimos las conexiones con esa direccion
#con awk '{print $valor}' recuperamos el valor de esa columna
	getConectDesdeUltimo(){
		SAVEIFS=$IFS
		IFS=$(echo -e "\n\b")
		arrayAux=($(last -w -i|grep -v 0.0.0.0|grep -e "logged" |awk '{print $1, $3, $7, $9, $10}'))
		IFS=$SAVEIFS
	}

	UsuariosEnArray(){
		#llamamos la funcion ${#array[@]}uarios y con =$? cachamos el valor de retorno
		NumArray=${#array[@]}
		cont=0
		#variable para incrementar en en while
		i="0"
		while [ $i -lt $NumArray ]
		do
			usuario=$(echo ${array[$i]}|cut -d " " -f1)
			direccion=$(echo ${array[$i]}|cut -d " " -f2)
			conexion=$(echo ${array[$i]}|cut -d " " -f3)
			desconexion=$(echo ${array[$i]}|cut -d " " -f4)
			tiempo=$(echo ${array[$i]}|cut -d " " -f5)
				if [ $desconexion == "logged" ];then
							HORA=$(date +"%H:%M ")
							tiempo=$((( $(date -ud $HORA +'%s')-$(date -ud $conexion +'%s'))/60))
						#else
						#	tiempo=$((( $(date -ud $desconexion +'%s')-$(date -ud $conexion +'%s'))/60))
				fi
			cont=cont+1
			if [ $cont == 8 ]; then
				cont=0
			fi
			tput setaf $cont
			echo -e $usuario"		"$direccion"	    "$conexion"                     "$desconexion"                  "$tiempo" min"

			i=$[$i+1]
		done
	}

	cambiarLogaDesc(){
		getConectDesdeUltimo
		NumArrayAux=${#arrayAux[@]}
		#variable para incrementar en el while

		i="0"
		while [ $i -lt ${#array[@]} ]; do
			usuario=$(echo ${array[$i]}|cut -d " " -f1)
			direccion=$(echo ${array[$i]}|cut -d " " -f2)
			conexion=$(echo ${array[$i]}|cut -d " " -f3)
			desconexion=$(echo ${array[$i]}|cut -d " " -f4)
			tiempo=$(echo ${array[$i]}|cut -d " " -f5)

			encontrado="0"
			j="0"
			#buscar en los actuales
			while [ $j -lt $NumArrayAux ] #no entra si esta vacio
			do

				usuarioAux=$(echo ${arrayAux[$j]}|cut -d " " -f1)
				direccionAux=$(echo ${arrayAux[$j]}|cut -d " " -f2)
				conexionAux=$(echo ${arrayAux[$j]}|cut -d " " -f3)
				desconexionAux=$(echo ${arrayAux[$j]}|cut -d " " -f4)
				tiempoAux=$(echo ${arrayAux[$j]}|cut -d " " -f5)

				if [ "$usuarioAux" == "$usuarioa" ]; then

					if [ "$direccionAux" == "$direccion" ]; then
						encontrado="1"
					fi
				fi
				j=$[$j+1]
			done


			#si no esta es porque esta desonectado
			if(($encontrado == "0"));then
				if [ "$desconexion" == "logged" ]; then

					 arrayDesconectados=($(last -w -i $usuario |grep -v 0.0.0.0|grep -v "logged"|awk '{print $1, $3, $7, $9, $10}'))
					 k="0"
					 while [ $k -lt ${#arrayDesconectados[@]} ]; do
							direccionDesco=$(echo ${arrayDesconectados[$k]}|cut -d " " -f2)
							conexionDesco=$(echo ${arrayDesconectados[$k]}|cut -d " " -f3)
							#echo ${#arrayDesconectados}

							if [ "$direccion" == "$direccionDesco" ]; then

								if [ "$conexion" == "$conexionDesco" ]; then
									usuarioa=$(echo ${arrayDesconectados[$k]}|cut -d " " -f1)
									desconexion=$(echo ${arrayDesconectados[$k]}|cut -d " " -f4)
									tiempo=$(echo ${arrayDesconectados[$k]}|cut -d " " -f5)
									cadena=$(echo -e $usuarioa" "$direccion" "$conexion" "$desconexion" "$tiempo)
									array[$i]=$cadena
									#remplaza la cadena con el estado de desconexion
									break
								fi
							fi
							k=$[$k+1]
					 done
				fi
			fi


			i=$[$i+1]
		done
	}

	remplazarSiExiste(){
		i="0"
		cont="0"
		encontrado="0"
		arrayDesconectados=()
		while [ $i -lt ${#array[@]} ]; do
			usuario=$(echo ${array[$i]}|cut -d " " -f1)
			direccion=$(echo ${array[$i]}|cut -d " " -f2)
			conexion=$(echo ${array[$i]}|cut -d " " -f3)
			desconexion=$(echo ${array[$i]}|cut -d " " -f4)
			tiempo=$(echo ${array[$i]}|cut -d " " -f5)

			usuarioa=$( echo ${arrayAux[0]}| cut -d " " -f1) #Se obtienen los datos del ultimo en conectarse
			direcciona=$( echo ${arrayAux[0]}| cut -d " " -f2)
			if [[ "$usuario" == "$usuarioa" && "$direccion" == "$direcciona" ]];
				then
					encontrado="1"
				else
					arrayDesconectados[$cont]=${array[$i]}
					cont=$[$cont+1]
			fi
			i=$[$i+1]
		done
		if(( $encontrado == "1" ));then
			num=${#arrayDesconectados[@]}
			SAVEIFS=$IFS
			IFS=$(echo -e "\n\b")
			arrayDesconectados[$num]=${arrayAux[0]}
			array=( ${arrayDesconectados[*]})
			SAVEIFS=$IFS
			else
				max=${#array[@]}
				array[$max]=${arrayAux[0]}
		fi

	}
	actualizarArray(){
		SAVEIFS=$IFS
		usuarioa=""
		IFS=$(echo -e "\n\b")

		#wc -l cuenta las lineas de lo que se le pasa
		numActual=$(last -i |grep -E "logged"|grep -v 0.0.0.0| wc -l)

		if (($numActual > $numAnterior)); then
		#	getConectDesdeUltimo
			let nuevos="$numActual-$numAnterior"
			SAVEIFS=$IFS
			IFS=$(echo -e "\n\b")
			arrayAux=($(last -w -i|grep -v 0.0.0.0|grep -e "logged" |awk '{print $1, $3, $7, $9, $10}'))
			IFS=$SAVEIFS
			remplazarSiExiste
				#verificar si ya esta el usuario con la direccion y desconectado
				#entonces eliminar el anterior y agregar la conexion al final

		else
				if(($numActual<$numAnterior));then
					cambiarLogaDesc
				fi
		fi
		numAnterior=$numActual
	}
#last -w -i|grep -v 0.0.0.0|grep -v "logged" |awk '{print $1"|", $3"|",$4" "$5" "$6"|",$7"|",$9"|", $10}'|sort -k 3 -r

	mostrar(){
		tput setaf 7 #color blanco
		echo "Usuario 	Direccion	Hora_de_conexion	Hora_de_desconexion	Tiempo_de_conexion"
		tput setaf 1
		UsuariosEnArray
}

	typeset -i bandera
	bandera=0

	SAVEIFS=$IFS
	IFS=$(echo -e "\n\b")
	array=($(last -w -i|grep -v 0.0.0.0|grep -e "logged" |tac|awk '{print $1, $3, $7, $9, $10}'))
		IFS=$SAVEIFS
		numAnterior=${#array[@]}
		mostrar

	while [ $bandera == 0 ]
	do
		clear
		actualizarArray
		mostrar
		sleep 2
	done
