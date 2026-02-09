#!/usr/bin/env bash
set -eo pipefail

readonly LAUNCHER_CLIENT_ID="Game_Launcher"
readonly LAUNCHER_HOME="https://launcher.zwift.com/launcher"
readonly ZWIFT_REALM_URL=https://secure.zwift.com/auth/realms/zwift
readonly COOKIE="cookie.jar"

curl -sS "${LAUNCHER_HOME}" --cookie-jar "${COOKIE}"
REQUEST_STATE="$(grep -oP "OAuth_Token_Request_State\s+\K.*$" "${COOKIE}")"

AUTHENTICATE_URL="$(curl -sSL --get --cookie "${COOKIE}" --cookie-jar "${COOKIE}" \
    --data-urlencode "response_type=code" \
    --data-urlencode "client_id=${LAUNCHER_CLIENT_ID}" \
    --data-urlencode "redirect_uri=${LAUNCHER_HOME}" \
    --data-urlencode "login=true" \
    --data-urlencode "scope=openid" \
    --data-urlencode "state=${REQUEST_STATE}" \
    "${ZWIFT_REALM_URL}/protocol/openid-connect/auth" \
    | grep -oP '<form id="form" class="zwift-form" action="\K(.+?)(?=" method="post">)' \
    | sed -e 's/\&amp;/\&/g')"

ACCESS_CODE="$(curl -sS --cookie "${COOKIE}" --cookie-jar "${COOKIE}" \
    --data-urlencode "username=${ZWIFT_USERNAME}" \
    --data-urlencode "password=${ZWIFT_PASSWORD}" \
    --write-out "%{redirect_url}" \
    "${AUTHENTICATE_URL}" \
    | grep -oP "code=\K.+$")"

AUTH_TOKEN_JSON="$(curl -sS --cookie "${COOKIE}" --cookie-jar "${COOKIE}" \
    --data-urlencode "client_id=${LAUNCHER_CLIENT_ID}" \
    --data-urlencode "redirect_uri=${LAUNCHER_HOME}" \
    --data-urlencode "code=${ACCESS_CODE}" \
    --data-urlencode "grant_type=authorization_code" \
    --data-urlencode "scope=openid" \
    "${ZWIFT_REALM_URL}/protocol/openid-connect/token")"

rm "${COOKIE}"

echo "${AUTH_TOKEN_JSON}"
