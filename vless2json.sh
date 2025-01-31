#!/bin/sh

source "$(dirname "$0")/lib/options.sh"
function urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

if  echo "$URL" | grep -Eo 'https://[^/]+' > /dev/null; then
    echo "https:// to vless:// DONE!!!"
    URL=$(curl -s $URL)
fi

if ! echo "$URL" | grep -Eo 'vless://[^/]+' > /dev/null; then
	echo "vless: Invalid URI scheme."
	exit 1
fi

PARSE_ME=$(echo "$URL" | awk -F'://' '{print $2}')
QUERY=$(echo "$PARSE_ME" | awk -F '[?#]' '{print $2}')
USER_ID=$(echo "$PARSE_ME" | awk -F'[@:?]' '{print $1}')
SERVER_ADDRESS=$(echo "$PARSE_ME" | awk -F'[@:?]' '{print $2}')
SERVER_PORT=$(echo "$PARSE_ME" | awk -F'[@:?]' '{print $3}' | sed 's/[^0-9]*//g')
REMARKS=$(echo "$PARSE_ME" | awk -F '[#]' '{print $2}')

eval "$(echo "$QUERY" | awk -F '&' '{
        for(i=1;i<=NF;i++) {
                print $i
        }
}')"

NET_TYPE="$type"
TLS="$security"
ENCRYPTION=${encryption:-none}
HEADER_TYPE=${headerType:-none}
FINGERPRINT="$fp"
SNI="$sni"
SID="$sid"
SPX=$(urldecode "$spx")
PUBLICKEY="$pbk"
FLOW="$flow"
ALPN=$(urldecode "$alpn")
HEADERS_HOST="$host"
SETTINGS_PATH=$(urldecode "$path")
if [ -z "${SETTINGS_PATH}" ]; then
  SETTINGS_PATH=$(urldecode "$serviceName")
fi

source "$(dirname "$0")/lib/stream-settings.sh"

if [ "$NET_TYPE" == "tcp" ]; then
	STREAM_SETTINGS=$(gen_tcp)
elif [ "$NET_TYPE" == "ws" ]; then
	STREAM_SETTINGS=$(gen_ws)
elif [ "$NET_TYPE" == "quic" ]; then
	STREAM_SETTINGS=$(gen_quic)
elif [ "$NET_TYPE" == "grpc" ]; then
  STREAM_SETTINGS=$(gen_grpc)
else
	echo "Unsupported network type! Supported net types: (tcp | quic | ws | grpc)."
	exit 1
fi

jq . <<EOF > "${PREFIX_DIR}config.json"
{
    "log" : {
        "level" : "debug"
    },
    "inbounds" : [ {
        "type" : "tun",
        "interface_name" : "tun0",
        "domain_strategy" : "ipv4_only",
        "inet4_address" : "172.16.250.1/30",
        "auto_route" : false,
        "strict_route" : false,
        "sniff" : true
    } ],
    "outbounds" : [ {
        "type" : "vless",
        "tag" : "$REMARKS",
        "server" : "$SERVER_ADDRESS",
        "server_port" : $SERVER_PORT,
        "uuid" : "$USER_ID",
        "flow" : "$FLOW",
        "tls" : {
            "enabled" : true,
            "server_name" : "$SNI",
            "utls" : {
                "enabled" : true,
                "fingerprint" : "$FINGERPRINT"
            },
            "reality" : {
                "enabled" : true,
                "public_key" : "$PUBLICKEY",
                "short_id" : "$SID"
            }
        },
        "packet_encoding" : "xudp"
    } ],
    "route" : {
        "auto_detect_interface" : true
    }
}
EOF
