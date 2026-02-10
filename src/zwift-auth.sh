#!/usr/bin/env bash
set -eo pipefail

readonly DEBUG="${DEBUG:-0}"
if [[ ${DEBUG} -eq 1 ]]; then set -x; fi

readonly ZWIFT_USERNAME="${ZWIFT_USERNAME:?}"
readonly ZWIFT_PASSWORD="${ZWIFT_PASSWORD:?}"

readonly LAUNCHER_CLIENT_ID="Game_Launcher"
readonly LAUNCHER_HOME="https://launcher.zwift.com/launcher"
readonly ZWIFT_REALM_URL="https://secure.zwift.com/auth/realms/zwift"
readonly COOKIE="cookie.jar"

curl -sS "${LAUNCHER_HOME}" --cookie-jar "${COOKIE}"
request_state="$(grep -oP "OAuth_Token_Request_State\s+\K.*$" "${COOKIE}")"

authenticate_url="$(curl -sSL --get --cookie "${COOKIE}" --cookie-jar "${COOKIE}" \
    --data-urlencode "response_type=code" \
    --data-urlencode "client_id=${LAUNCHER_CLIENT_ID}" \
    --data-urlencode "redirect_uri=${LAUNCHER_HOME}" \
    --data-urlencode "login=true" \
    --data-urlencode "scope=openid" \
    --data-urlencode "state=${request_state}" \
    "${ZWIFT_REALM_URL}/protocol/openid-connect/auth" \
    | grep -oP '<form id="form" class="zwift-form" action="\K(.+?)(?=" method="post">)' \
    | sed -e 's/\&amp;/\&/g')"

access_code="$(curl -sS --cookie "${COOKIE}" --cookie-jar "${COOKIE}" \
    --data-urlencode "username=${ZWIFT_USERNAME}" \
    --data-urlencode "password=${ZWIFT_PASSWORD}" \
    --write-out "%{redirect_url}" \
    "${authenticate_url}" \
    | grep -oP "code=\K.+$")"

auth_token_json="$(curl -sS --cookie "${COOKIE}" --cookie-jar "${COOKIE}" \
    --data-urlencode "client_id=${LAUNCHER_CLIENT_ID}" \
    --data-urlencode "redirect_uri=${LAUNCHER_HOME}" \
    --data-urlencode "code=${access_code}" \
    --data-urlencode "grant_type=authorization_code" \
    --data-urlencode "scope=openid" \
    "${ZWIFT_REALM_URL}/protocol/openid-connect/token")"

rm "${COOKIE}"

echo "${auth_token_json}"
