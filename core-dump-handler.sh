#!/bin/bash

#
# sysctl -w kernel.core_pattern='|/bin/core-dump-handler.sh -c=%c -e=%e -p=%p -s=%s -t=%t -d=/var/log/core -r=10'
#

PATH="/bin:/sbin:/usr/bin:/usr/sbin"

umask 0177

DIRECTORY="/var/log/core"
ROTATE=10

for i in "$@"
do
case $i in
    -c=*|--limit-size=*)
        LIMIT_SIZE="${i#*=}"; shift
    ;;
    -e=*|--exe-name=*)
        EXE_NAME="${i#*=}"; shift
    ;;
    -p=*|--pid=*)
        REAL_PID="${i#*=}"; shift
    ;;
    -s=*|--signal=*)
        SIGNAL="${i#*=}"; shift
    ;;
    -t=*|--timestamp=*)
        TS="${i#*=}"; shift
    ;;
    -d=*|--dir=*)
        DIRECTORY="${i#*=}"; shift
    ;;
    -r=*|--rotate=*)
        ROTATE="${i#*=}"; shift
    ;;
esac
done

if [[ "_0" = "_${LIMIT_SIZE}" ]]; then
    exit 0
fi

if lz4 --version >/dev/null 2>&1; then
    COMPRESSOR="lz4 -1"
    EXT=.lz4
elif lzop --version >/dev/null 2>&1; then
    COMPRESSOR="lzop -1"
    EXT=.lzo
elif gzip --version >/dev/null 2>&1; then
    COMPRESSOR="gzip -3"
    EXT=.gz
else
    COMPRESSOR=cat
    EXT=
fi

if [[ ! -d "${DIRECTORY}" ]]; then
    mkdir -p "${DIRECTORY}"
    chown root:root "${DIRECTORY}"
    chmod 0600 "${DIRECTORY}"
fi

head --bytes "${LIMIT_SIZE}" \
    | ${COMPRESSOR} > "${DIRECTORY}/dump-${TS}-${EXE_NAME}-${REAL_PID}-${SIGNAL}.core${EXT}"

find "${DIRECTORY}" -name 'dump*' -type f -printf "%T@ %p\n" \
	| sort \
	| head --lines "-${ROTATE}" \
	| cut --delimiter ' ' --fields 2 \
	| xargs --no-run-if-empty rm

