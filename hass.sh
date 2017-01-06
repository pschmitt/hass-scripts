#!/usr/bin/env bash

cd "$(readlink -f "$(dirname "$0")")" || exit 9

HASS_URL="https://$(awk '/base_url/ { print $2;exit }' ../config/secrets.yaml)"
HASS_PASSWORD=$(awk '/http_password/ { print $2;exit }' ../config/secrets.yaml)

usage() {
    echo "Usage: $(basename "$0") get|post API_ENDPOINT"
}

__rq() {
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

case "$1" in
    g|get|GET|G)
        rq_get "$2" "$3"
        ;;
    p|post|POST|p)
        rq_post "$2" "$3"
        ;;
    *)
        usage
        exit 2
        ;;
esac
