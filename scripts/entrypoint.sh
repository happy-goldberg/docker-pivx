#!/bin/sh
set -x

USER=pivx

chown -R ${USER} .
exec su-exec ${USER} "$@"
