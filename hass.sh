#!/usr/bin/env bash

HASS_URL="https://$(awk '/base_url/ { print $2;exit }' ../config/secrets.yaml)"
HASS_PASSWORD=$(awk '/http_password/ { print $2;exit }' ../config/secrets.yaml)


usage() {
    echo "Usage: $(basename "$0") get|post API_ENDPOINT"
}

__rq() {
    curl -qqs -X "$1" \
        -H "X-HA-ACCESS: $HASS_PASSWORD" \
        -H "Content-Type: application/json" \
        "${HASS_URL}/api/$2"
    echo
}

rq() {
    local method=$1
    shift
    local params=$@
    __rq "$method" "$params"
}

rq_get() {
    rq GET "$1"
}

rq_post() {
    rq POST "$1"
}

case "$1" in
    g|get|GET|G)
        rq_get "$2"
        ;;
    p|post|POST|p)
        rq_post "$2"
        ;;
    *)
        usage
        exit 2
        ;;
esac
