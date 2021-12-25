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

LOGINCMD=(curl -s -k -i
          -c $TESLA/cookie.txt
          -X POST
          -H "Content-Type: application/json"
          -d @$TESLA/creds.json
          https://$IP/api/login/Basic )

CMD="curl -s -k \
    -b $TESLA/cookie.txt \
    https://$IP/api/system_status/grid_status"

GWDOWNCOUNT=1
RETRYINTERVAL=10  # When the gateway is down

#$ALEXARC -e "speak: \
#   'Hey Susan, why don't you get your husband a beer?'"
#exit

while true;
do
    TIMESTAMP="$(date -I'seconds')"
    # Note explicit conversion of numbers to base 10; otherwise
    # they are interpreted as octal numbers, causing errors
    # with '08' and '09'.
    # Found fix at: https://stackoverflow.com/questions/24777597
    HOUR=$((10#$(date "+%H")))
    MIN=$((10#$(date "+%M")))

    # Changed on 2021-12-15 - get new token every time.
    # echo "Logging in..."
    max_retry=5
    counter=0
    until "${LOGINCMD[@]}" |grep token >/dev/null
    do
        sleep 5
        [[ counter -eq $max_retry ]] && echo "Failed!" && break
        #echo "Trying again. Try #$counter"
        ((counter++))
    done

    GSTATUS="$($CMD | jq -r '.grid_status')"

    echo "$TIMESTAMP,$GSTATUS" >> $OUTFILE

    if [[ "$GSTATUS" == "null" ]]  # Bad cookie? Or can't reach?
    then
        echo "$TIMESTAMP: Got a 'null'"
        sleep 10
        continue
    fi

    # Make sure we got a response from the Tesla Gateway.
    if [[ "$GSTATUS" == "" ]]
    then
        if [[ (($(($GWDOWNCOUNT % $RETRYINTERVAL)) == 0)) ]]
        then
            # Next loop
            echo "$TIMESTAMP: Announcing network drop..."
            $ALEXARC -e "speak: \
               'It looks like the Tesla gateway has dropped off \
                the network. I'll try again in ${RETRYINTERVAL} \
                minutes, or you can go out on the porch, open the \
                large cover, and push the reset button with a pencil'"
        fi
        sleep $SLEEP
        GWDOWNCOUNT=$(($GWDOWNCOUNT + 1))
        continue
    fi

    GWDOWNCOUNT=1

    if [[ $HOUR -eq 19 && $MIN -eq 13 ]]
    then
        echo "$TIMESTAMP: Announcing test..."
        $ALEXARC -e "speak: \
           'This is your daily test of the Clowder Cove gridwatcherPEYE \
           system. This is only a test. And oh...you can watch Jeopardy now.'"
    fi

    if [ -d '/dev/usb/' ]; then SILENCER=true; else SILENCER=false; fi
    if [[ "$GSTATUS" == "SystemGridConnected" ]]; then GRID=true; else GRID=false; fi

    if ! $GRID
    then
        if ! $SILENCER
        then
            echo "$TIMESTAMP: Announcing grid down..."
            $ALEXARC -e "speak: \
               'Clowder Cove grid is down. SAAAAAD. Unplug the car if \
                its charging and turn off the heatpump to conserve the \
                Powerwall. You can turn on the gas heater if your ass \
                gets too cold. You can silence this message by plugging \
                any USB device into any USB port on the gridwatcherpeye.'"
        fi
    else
        if $SILENCER
        then
            echo "$TIMESTAMP: Announcing silencer reminder..."
            $ALEXARC -e "speak: \
               'This is a reminder. Clowder Cove grid is up. Remove the USB \
               silencer dongle from the gridwatcherpeye.'"
        fi
    fi

    sleep $SLEEP

done
