#!/bin/bash
#Logs
scriptLog="/var/log/Planeta_Symantec.log"
function updateScriptLog() {
        echo -e "$(date +%d-%m-%Y\ %H:%M:%S) - ${1}" | tee -a "${scriptLog}"
}
#Evitar suspenso mientras se ejecute el script
updateScriptLog "Activando Caffeinate"
caffeinate -i -w $$ &
#Ruta de Dialog
dialogPath=/usr/local/bin/dialog

#En espera hasta que el usuario inicie sesión, para mostrar el aviso.
loggedInUser=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }')
while [[ -z "${loggedInUser}" || "${loggedInUser}" == "loginwindow" ]]; do
        loggedInUser=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }')
        updateScriptLog "Usuario no logeado; Pausando por 1 minuto"
        sleep 60
done

#Usuario logeado
loggedInUser=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }')

#Dialogos
dialogTitle="Reinicio requerido"
dialogMessage="**¡Atención!** \n\nTiene pendiente una actualización que requerirá de un reinicio."
helpmessage="Asistencia CRC:  \n- **Teléfono:** \n8118  \n\n- **Email:** \ncrc@planeta.es"
guardado="Guarde sus documentos. \n\nEn **2 minutos** empezará la actualización o acepte para comenzar de inmediato."
progreso="Se está instalando la actualización.\n\nEste proceso puede tardar unos minutos. Por favor, no apague el equipo."
progresopie="Actualizando y preparándose para reiniciar"
avisoreinicio="El equipo se reiniciará en **1 min.** \n\nGuarde todo lo que tenga abierto."
aplazado="\n\n**Ya no puede aplazar más este mensaje.** \n\nSi no acepta, la actualización comenzará automáticamente en **20 minutos.**"
dialogButton1="Aceptar"
#Rutas de imágenes detectando si está activado el modo oscuro o no
appleInterfaceStyle=$(/usr/bin/defaults read /Users/"${loggedInUser}"/Library/Preferences/.GlobalPreferences.plist AppleInterfaceStyle 2>&1)
if [[ "${appleInterfaceStyle}" == "Dark" ]]; then
        crcicon="https://ics.services.jamfcloud.com/icon/hash_7c0b81436e216725ce657a80782b993888ef7e894756b9007ed973dbcd709358"
        updateScriptLog "Modo oscuro detectado"
else
        crcicon="https://ics.services.jamfcloud.com/icon/hash_fc0a20f60d5c980ffb196f91600b7abda95d78e54e4c481b4bf57ac3c4129470"
        updateScriptLog "Modo claro detectado"
fi

#Tiempo de aplazados máximos
currentDeferralTime="3"

#Resta cuando se apliza un aplazo
reduceDeferralBy="1"

#El concentimiento del usuario es NO por defecto. Hasta que pase el tiempo máximo o el usuario acepete se mantendrá en bucle
userConsent=1

#Comienza el bucle hasta que pase el tiempo máximo o el usuario acepte.
while [[ userConsent -gt 0 ]]; do
        nonaggressiveButtonText="Aplazar"
        nonaggressiveDialogMessage="\n\n Si seleccionas \"**Aplazar**\" volverá a aparecer este mensaje en **1 hora.** \n\nNúmero de aplazos disponibles: **$currentDeferralTime** \n\nSi no selecciona ninguna opción, continuará automáticamente en **20 minutos.**"

        #Primer Dialog de notificación al usuario donde se realizará el bucle hasta que acepte.
        updateScriptLog "Iniciando aviso principal"
        "$dialogPath" \
                --title "$dialogTitle" \
                --titlefont size=22 \
                --message "$dialogMessage $nonaggressiveDialogMessage" \
                --button1text "$dialogButton1" \
                --button2text "$nonaggressiveButtonText" \
                --helpmessage "$helpmessage" \
                --width "325" \
                --height "450" \
                --messagefont size=16 \
                --position topright \
                --ontop \
                --messagealignment centre \
                --messageposition centre \
                --centericon \
                --icon "$crcicon" \
                --timer "1200"

        #Captura si el usuario deja pasar el tiempo (4), Acepta (0) o Aplaza(Nº de aplazo).
        dialogResult=$?
        #Mensaje por si el usuario intenta cerrar el aviso de forma fraudulenta.
        if [ "$dialogResult" = 10 ]; then
                nonaggressiveDialogMessage+="\n\n Esto no va a funcionar. Esta actualización es necesaria."

        #Si el usuario acepta o deja pasar el tiempo se cambia la cariable del concentimiento para que se termine el bucle.
        elif [ "$dialogResult" = 0 ] || [ "$dialogResult" = 4 ]; then
                userConsent=0
                updateScriptLog "El usuario ha aceptado o dejado pasar el tiempo"
                #Aviso sobre que guarde los documentos
                updateScriptLog "Avisando de que dispone de 2 minutos para guardar los archivos"
                "$dialogPath" \
                        --title "$dialogTitle" \
                        --message "$guardado" \
                        --position topright \
                        --titlefont size=22 \
                        --messagefont size=16 \
                        --messagealignment centre \
                        --messageposition centre \
                        --icon "$crcicon" \
                        --centericon \
                        --helpmessage $helpmessage \
                        --button1text Aceptar \
                        --ontop \
                        --timer "120" \
                        --width "325" \
                        --height "450" \
                        --quitkey [
                #Aviso del progreso de instalación
                updateScriptLog "Ejecutando política del symantec"
                "$dialogPath" \
                        --title "$dialogTitle" \
                        --message "$progreso" \
                        --icon "$crcicon" \
                        --centericon \
                        --titlefont size=22 \
                        --messagefont size=16 \
                        --messagealignment centre \
                        --messageposition centre \
                        --position topright \
                        --helpmessage $helpmessage \
                        --ontop \
                        --quitkey [ \
                        --button1disabled \
                        --progress \
                        --progresstext "$progresopie" \
                        --width "325" \
                        --height "450" \
                        &
                #Comandos que se ejecutará en este script.
                jamf policy -event symantecdistribucion
                #Finaliza la barra de progreso para continuar con el aviso final
                killall Dialog
                #Aviso de que se va a reiniciar el equipo en 1 min
                updateScriptLog "Aviso de que en 1 min se reinicará el equipo"
                "$dialogPath" \
                        --title "$dialogTitle" \
                        --message "$avisoreinicio" \
                        --icon "$crcicon" \
                        --centericon \
                        --titlefont size=22 \
                        --messagefont size=16 \
                        --messagealignment centre \
                        --messageposition centre \
                        --position topright \
                        --helpmessage "$helpmessage" \
                        --ontop \
                        --quitkey [ \
                        --button1disabled \
                        --timer "60" \
                        --width "325" \
                        --height "450" \
                        &
                #Programado del reinicio
                sudo shutdown -r +1 &
                updateScriptLog "Reinicio programado en 1 min"
                exit 0
        #Si el usuario no acepta o agota los aplazos
        else
                #Comprueba que los aplazos han llegado al limite y pone en espera el script
                if [[ "$currentDeferralTime" -gt 0 ]]; then
                        updateScriptLog "Aplazos pendientes: $currentDeferralTime"
                        updateScriptLog "Proceso en espera 1 hora"
                        sleep 3600
                        #Resta del nº máximo de aplazos a 1 menos
                        currentDeferralTime=$((currentDeferralTime - reduceDeferralBy))
                        # Si el nº de Aplazos llega a 0 forzará la ejecución
                        if [[ "$currentDeferralTime" == 0 ]]; then
                                userConsent=0
                                updateScriptLog "Aplazos llegados al límite, el usuario dispone de 20 min para proceder"
                                #Aviso de que no podrá posponer más este aviso
                                "$dialogPath" \
                                        --title "$dialogTitle" \
                                        --message "$dialogMessage $aplazado" \
                                        --titlefont size=22 \
                                        --messagefont size=16 \
                                        --messagealignment centre \
                                        --messageposition centre \
                                        --icon "$crcicon" \
                                        --centericon \
                                        --position topright \
                                        --timer "1200" \
                                        --helpmessage "$helpmessage" \
                                        --button1text "$dialogButton1" \
                                        --ontop \
                                        --quitkey [ \
                                        --width "325" \
                                        --height "450"
                                #Aviso sobre que guarde los documentos
                                updateScriptLog "Avisando de que dispone de 2 minutos para guardar los archivos"
                                "$dialogPath" \
                                        --title "$dialogTitle" \
                                        --message "$guardado" \
                                        --position topright \
                                        --titlefont size=22 \
                                        --messagefont size=16 \
                                        --messagealignment centre \
                                        --messageposition centre \
                                        --icon "$crcicon" \
                                        --centericon \
                                        --helpmessage "$helpmessage" \
                                        --button1text Aceptar \
                                        --timer "120" \
                                        --ontop \
                                        --width "325" \
                                        --height "450" \
                                        --quitkey [
                                #Aviso del progreso de instalación
                                updateScriptLog "Ejecutando política del symantec"
                                "$dialogPath" \
                                        --title "$dialogTitle" \
                                        --message "$progreso" \
                                        --icon "$crcicon" \
                                        --centericon \
                                        --position topright \
                                        --titlefont size=22 \
                                        --messagefont size=16 \
                                        --messagealignment centre \
                                        --messageposition centre \
                                        --helpmessage "$helpmessage" \
                                        --ontop \
                                        --quitkey [ \
                                        --button1disabled \
                                        --progress \
                                        --progresstext "$progresopie" \
                                        --width "325" \
                                        --height "450" \
                                        &
                                #Comandos que se ejecutará en este script.
                                jamf policy -event symantecdistribucion
                                #Finaliza la barra de progreso para continuar con el aviso final
                                killall Dialog
                                #Aviso de que se va a reiniciar el equipo en 1 min
                                updateScriptLog "Aviso de que en 1 min se reinicará el equipo"
                                "$dialogPath" \
                                        --title "$dialogTitle" \
                                        --message "$avisoreinicio" \
                                        --icon "$crcicon" \
                                        --centericon \
                                        --position topright \
                                        --titlefont size=22 \
                                        --messagefont size=16 \
                                        --messagealignment centre \
                                        --messageposition centre \
                                        --helpmessage "$helpmessage" \
                                        --ontop \
                                        --quitkey [ \
                                        --button1disabled \
                                        --timer "60" \
                                        --width "325" \
                                        --height "450" \
                                        &
                                #Programado del reinicio
                                sudo shutdown -r +1 &
                                updateScriptLog "Reinicio programado en 1 min"
                                exit 0
                        fi
                else
                        :
                fi
        fi
        #Finalización del bucle
done
