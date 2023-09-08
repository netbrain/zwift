##!/usr/bin/env bash

set -e

if [[ ! -f "/home/user/Zwift/.zwift-credentials" ]]
then
  echo "Zwift credentials file missing!"
  exit 1
fi

# Load credentials env variables
source /home/user/Zwift/.zwift-credentials

LAUNCHER_CLIENT_ID="Game_Launcher"
LAUNCHER_HOME="https://launcher.zwift.com/launcher"

ZWIFT_REALM_URL=https://secure.zwift.com/auth/realms/zwift
COOKIE="cookie.jar"

curl -sS $LAUNCHER_HOME --cookie-jar "$COOKIE"
REQUEST_STATE=$(grep -oP "OAuth_Token_Request_State\s+\K.*$" "$COOKIE")

AUTHENTICATE_URL=$(curl -sSL --get --cookie "$COOKIE" --cookie-jar "$COOKIE" \
  --data-urlencode "response_type=code" \
  --data-urlencode "client_id=$LAUNCHER_CLIENT_ID" \
  --data-urlencode "redirect_uri=$LAUNCHER_HOME" \
  --data-urlencode "login=true" \
  --data-urlencode "scope=openid" \
  --data-urlencode "state=$REQUEST_STATE" \
  "$ZWIFT_REALM_URL/protocol/openid-connect/auth" |
  grep -oP '<form id="form" class="zwift-form" action="\K(.+?)(?=" method="post">)' |
  sed -e 's/\&amp;/\&/g')

ACCESS_CODE=$(curl -sS --cookie "$COOKIE" --cookie-jar "$COOKIE" \
  --data-urlencode "username=$ZWIFT_USERNAME" \
  --data-urlencode "password=$ZWIFT_PASSWORD" \
  --write-out "%{REDIRECT_URL}" \
  "$AUTHENTICATE_URL" | grep -oP "code=\K.+$")

AUTH_TOKEN_JSON=$(curl -sS --cookie "$COOKIE" --cookie-jar "$COOKIE" \
  --data-urlencode "client_id=$LAUNCHER_CLIENT_ID" \
  --data-urlencode "redirect_uri=$LAUNCHER_HOME" \
  --data-urlencode "code=$ACCESS_CODE" \
  --data-urlencode "grant_type=authorization_code" \
  --data-urlencode "scope=openid" \
  "$ZWIFT_REALM_URL/protocol/openid-connect/token")

# Or if going as the launcher does it
# the GET request to /ride redirects with a new refresh token that can be used for auth
# REFRESH_TOKEN=$(curl -sSL --get --cookie "$COOKIE" --cookie-jar "$COOKIE" \
#     "$LAUNCHER_HOME/ride" \
#     --write-out "%{url_effective}" | grep -oP "code=zwift_refresh_token\K.+$")

# AUTH_TOKEN_JSON=$(curl -sS --cookie "$COOKIE" --cookie-jar "$COOKIE" \
#   --data-urlencode "client_id=$LAUNCHER_CLIENT_ID" \
#   --data-urlencode "redirect_uri=$LAUNCHER_HOME" \
#   --data-urlencode "refresh_token=$REFRESH_TOKEN" \
#   --data-urlencode "grant_type=refresh_token" \
#   --data-urlencode "scope=openid" \
#   "$ZWIFT_REALM_URL/protocol/openid-connect/token")

rm $COOKIE

echo $AUTH_TOKEN_JSON
