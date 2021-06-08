#!/usr/bin/env bash
set -e
# requires packages:  jq bash
# fedora: dnf install -y jq bash
# debian: apt install -y jq bash

# Message format should allways container a "msg-version" and "msg-type".
# msg-type then is used to invoke a script. If it the messsage type contains a "/" then it is converted to "-"  a "config/msg" becomes "config-msg" and is called 

# Read (flat) json from STDIN and transform to shell variables
DIRNAME=$(dirname "$0")

for FILENAME in /etc/mqtt-runner.conf $HOME/.mqtt-runner.conf $DIRNAME/mqtt-runner.conf; do
    if [ -f "$FILENAME" ]; then
        CONFIGURATION_FILE=$FILENAME
	break
    fi
done

while [[ $# > 0 ]]
do
    ARG="$1"
    case $ARG in
        -c|--configurion-file)
            shift
            CONFIGURATION_FILE=$1
	    if [ ! -f "$CONFIGURATION_FILE" ]; then
            	echo "configuration file not found: $CONFIGURATION_FILE"
                exit 1
            fi
            ;;

        *)
            UNPARSED_ARGS+=($1)
            ;;
    esac
    shift
done

. "$CONFIGURATION_FILE"

HOST=${HOST:="localhost"}
TOPIC=${TOPIC:="test"}
QOS=${QOS:="0"} # quality of service

if [ $QOS -gt 0 ]; then
    ID=${ID:="server"}
    OPTIONS="-c -i $ID"
fi

# With QOS == 2 the messages are stored for the ID == server until the
# subscriber returns and pulls them

while true; do
    mosquitto_sub -h $HOST -t $TOPIC -q $QOS $OPTIONS -C 1 |\
    "$DIRNAME/json2shell.sh" --exex-dir "$DIRNAME/scripts"
done

