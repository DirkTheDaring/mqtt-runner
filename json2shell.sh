#!/usr/bin/env bash

# Read (flat) json from STDIN and transform it to shell variables and call a subsequent script
# based on "msg-type"

#set -ex
__EXEC_DIR=$(dirname "$0")/scripts
# requires packages:  jq bash
# fedora: dnf install -y jq bash
# debian: apt install -y jq bash

# Rules
# 1. Message format should always contain a "msg-version" and "msg-type".
# 2. if the msg-type value contains a "/"  then it is converted to "-" as
#    msg-type is used to call a script, e.g. a "config/msg" becomes "config-msg" 
# 3. It is fire and forget, we ignore any errors in scripts

# json format:
# { "msg-type": "<VALUE>",
#   "msg-version": "<VALUE>",
#   ... payload...  
# }

while [[ $# > 0 ]]
do
    ARG="$1"
    case $ARG in
        --exec-dir)
            shift
            __EXEC_DIR=$1
            ;;

        *)
            UNPARSED_ARGS+=($1)
            ;;
    esac
    shift
done

eval $(jq '. + {__keys: (keys|join(" ")|gsub("-";"_")|ascii_upcase)}'|\
 jq -r -n 'def q: if type=="string" then @sh else tojson|@sh end; foreach inputs as $in (-1;.+1; . as $n   | $in   | to_entries[]   | "\(.key|gsub("-";"_")|ascii_upcase + ($n|tostring) )=\(.value|q)" )| "s/^[ \t]*PATH=.*$//"')

I=0
eval __KEYS=\$__KEYS$I

while [ -n "$__KEYS" ] ; do

    # handle this in a subprocess with ()
    
    for __KEY in $__KEYS; do
        eval export $__KEY="\$$__KEY$I"
    done
    
    # replace "/"
    MSG_TYPE=${MSG_TYPE//\//--}

    if [ -f "$__EXEC_DIR/$MSG_TYPE" ]; then
        "$__EXEC_DIR/$MSG_TYPE"
    else
        echo "not found (dropped): $MSG_TYPE"
        break
    fi 
   
    # cleanup exported keys 
    eval export -n $__KEYS

    I=$(( I + 1 ))
    eval __KEYS=\$__KEYS$I
done

