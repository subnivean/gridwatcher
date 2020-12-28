#!/bin/bash

TESLA='/home/pi/.tesla'
OUTFILE="output/gridstatus.log"
SLEEP=60  # seconds

# `alexa-remote-control.sh` settings
# export EMAIL='sjbriere@gmail.com'
# export PASSWORD='xxxxxxxxx'
export LANGUAGE='en-US'
export TTS_LOCALE='en-US'
export AMAZON='amazon.com'
export ALEXA='alexa.amazon.com'
export TMP='/home/pi/.alexa-remote-control'

ALEXARC='/home/pi/github/alexa-remote-control/alexa_remote_control.sh'

IP="$(grep 'IP=' $TESLA/secrets |cut -d'=' -f2)"
CMD="curl -sk https://$IP/api/system_status/grid_status"

GWDOWNCOUNT=0
RETRYINTERVAL=10  # When the gateway is down

while true;
do
    TIMESTAMP="$(date -I'seconds')"
    HOUR=$(date "+%H")
    MIN=$(date "+%M")
    GSTATUS="$($CMD | jq -r '.grid_status')"

    echo "$TIMESTAMP,$GSTATUS" >> $OUTFILE

    # Make sure we got a response from the Tesla Gateway.
    if [[ "$GSTATUS" == "" ]]
    then
        if [[ (($(($GWDOWNCOUNT % $RETRYINTERVAL)) == 0)) ]]
        then
            # Next loop
            $ALEXARC -e "speak: 'It looks like the Tesla gateway has dropped off the Wifi network. I'll try again in ${RETRYINTERVAL} minutes, or you can go out on the porch, open the large cover, and push the reset button with a pencil'"
        fi
        sleep $SLEEP
        GWDOWNCOUNT=$(($GWDOWNCOUNT + 1))
        continue
    fi

    GWDOWNCOUNT=0

    if [[ "$HOUR" -eq "19" && "$MIN" -eq "10" ]]
    then
        $ALEXARC -e "speak: 'This is your daily test of the Clowder Cove gridwatcherPEYE system. This is only a test. And oh - you can watch Jeopardy now.'"
    fi

    if [ -d '/dev/usb/' ]; then SILENCER=true; else SILENCER=false; fi
    if [[ "$GSTATUS" == "SystemGridConnected" ]]; then GRID=true; else GRID=false; fi

    if ! $GRID
    then
        if ! $SILENCER
        then
            $ALEXARC -e "speak: 'Clowder Cove grid is down. SAAAAAD. Unplug the car if it's charging and turn off the heatpump (using the power button on the remote) to conserve the Powerwall. You can turn on the gas heater if your ass gets too cold. You can silence this message by plugging any USB device into the gridwatcherpeye.'"
        fi
    else
        if $SILENCER
        then
            $ALEXARC -e "speak: 'This is a reminder. Clowder Cove grid is up. Remove the USB silencer dongle from the gridwatcherpeye.'"
        fi
    fi

    sleep $SLEEP

done
