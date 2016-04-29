if [ "$(hostname)" == "tunnel" ]; then
    DOMAIN=tunnel.neocastnetworks.com
    EXTRA_ARGS="-tunnelAddr=:443 \
                -tlsCrt=server.crt \
                -tlsKey=server.key \
                -log-level=INFO \
                -log=ngrokd.log"
    NGROKD="./ngrokd"
else
    if [ "$DOMAIN" == "" ]; then
        DOMAIN=localhost
    fi
    EXTRA_ARGS=""
    NGROKD="../bin/ngrokd"
fi

${NGROKD} \
    -httpAddr="" \
    -httpsAddr="" \
    -domain=${DOMAIN} \
    -authTokens="ngrok_authtokens.txt" \
    ${EXTRA_ARGS} \
    "$@"
