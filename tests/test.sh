#!/usr/bin/env bash
set -ex
DIRNAME=$(dirname "$0")

for FILENAME in /etc/mqtt-runner.conf $DIRNAME/../mqtt-runner.conf; do
  if [ -f "$FILENAME" ]; then
	CONFIGURATION_FILE=$FILENAME
	break
  fi
done

. "$CONFIGURATION_FILE"

HOST=${HOST:="localhost"}
TOPIC=${TOPIC:="test"}
QOS=${QOS:="0"} # quality of service

#if [ $QOS -gt 0 ]; then
#  ID=${ID:="server"}
#  OPTIONS="-c -i $ID"
#fi

mosquitto_pub -h $HOST -t $TOPIC -q $QOS -f "$1"
