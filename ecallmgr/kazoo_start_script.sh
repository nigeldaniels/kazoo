#!/bin/bash

# Script to start ecallmgr

# Set necessary variables
LOG_DIR="/var/log/kazoo"
LOG_FILE="${LOG_DIR}/ecallmgr.log"
HOME=/opt/kazoo
BINDIR=/opt/kazoo/erts-8.3.5.7/bin  # Update to the directory containing Erlang binaries
MAX_WAIT=2  # Maximum wait time in seconds

# Environment setup for Kazoo
if [ -f /etc/default/kazoo ]; then
    . /etc/default/kazoo
fi

if [ -f /etc/sysconfig/kazoo ]; then
    . /etc/sysconfig/kazoo
fi

# Default values for Kazoo
NAME=${KAZOO_NAME:-kazoo-ecallmgr}
USER=${KAZOO_USER:-kazoo}
BIN_FILE=${KAZOO_BIN:-/opt/kazoo/bin/kazoo}  # Assuming kazoo is the starting point
PID_FILE=${KAZOO_PID:-/var/run/kazoo/${NAME}.pid}
export HOME=${KAZOO_ROOT:-/opt/kazoo}
export KAZOO_NODE="${NAME}"
export BINDIR

# Detect core count
CORES=$(grep -E "^processor" /proc/cpuinfo | wc -l)
if [ "${CORES}" = "1" ]; then
    BEAM=beam
else
    BEAM=beam.smp
fi

# Start ecallmgr function
start() {
    echo "Starting ecallmgr..."

    # Start Kazoo (ecallmgr as part of it)
    ${BIN_FILE} start

    # Wait for the log file to be created
    echo "Waiting for log file at ${LOG_FILE}..."
    for (( i=1; i<=MAX_WAIT; i++ )); do
        if [ -f "${LOG_FILE}" ]; then
            echo "Tailing log file at ${LOG_FILE}"
            tail -f ${LOG_FILE}
            return
        fi
        sleep 1
    done

    echo "Log file not created by ecallmgr. Creating log file now."
    touch ${LOG_FILE}
    tail -f ${LOG_FILE}
}

# Execute start function
start
