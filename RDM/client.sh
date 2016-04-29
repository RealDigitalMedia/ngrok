../bin/ngrok \
    -log-level=DEBUG \
    -log=stdout \
    -config=config.yml \
    "$@"
