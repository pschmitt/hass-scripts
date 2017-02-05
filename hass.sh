#!/usr/bin/env bash

cd "$(readlink -f "$(dirname "$0")")" || exit 9

HASS_URL="https://$(awk '/base_url/ { print $2;exit }' ../config/secrets.yaml)"
HASS_PASSWORD=$(awk '/http_password/ { print $2;exit }' ../config/secrets.yaml)

usage() {
    echo -e "Usage: $(basename "$0") ACTION API_ENDPOINT [DATA]\n"
    echo -e "ACTION: raw|script|light|scene|event\n"
    echo -e "- raw [GET|POST] API_ENDPOINT [DATA]"
    echo -e "- script SCRIPT_NAME"
    echo -e "- light on|off|toggle LIGHT_NAME"
    echo -e "- scene SCENE_NAME"
    echo -e "- event EVENT_NAME"
}

__rq_curl() {
    if [[ -n "$3" ]]
    then
        local json_data="-d $3"
    fi
    curl -qqs -X "$1" \
        -H "X-HA-ACCESS: $HASS_PASSWORD" \
        -H "Content-Type: application/json" \
        "$json_data" \
        "${HASS_URL}/api/$2"
    echo
}

__rq_httpie() {
    http -j -p b "$1" "${HASS_URL}/api/$2" \
        "X-HA-ACCESS:$HASS_PASSWORD" $3
}

__rq() {
    # Use httpie by default (if available)
    if command -v http > /dev/null 2>&1
    then
        __rq_httpie $*
    else
        __rq_curl $*
    fi
}

rq() {
    local method="$1"
    local endpoint="$2"
    local params="$3"
    __rq "$method" "$endpoint" "$params"
}

rq_get() {
    rq GET "$1" "$2"
}

rq_post() {
    rq POST "$1" "$2"
}

# Shortcut actions
script() {
    rq POST "services/script/$1"
}

event() {
    rq POST "events/$1"
}

notify() {
    rq POST "services/notify/$1" message=$2
}

light() {
    rq POST "services/light/$1" entity_id=$2
}

scene() {
    rq POST "services/scene/turn_on" entity_id=$1
}

case "$1" in
    r|raw)
        case "$2" in
            g|get|GET|G)
                rq_get "$3" "$4"
                ;;
            p|post|POST|p)
                rq_post "$3" "$4"
                ;;
            *)
                usage
                exit 2
                ;;
        esac
        ;;
    l|light)
        case "$2" in
            on)
                light turn_on "$3"
                ;;
            off)
                light turn_off "$3"
                ;;
            toggle)
                light toggle "$3"
                ;;
        esac
        ;;
    s|script)
        script "$2"
        ;;
    scene)
        scene "$2"
        ;;
    e|event)
        event "$2"
        ;;
    n|notify)
        notify "$2" "$3"
        ;;
    *)
        usage
        exit 2
        ;;
esac
