#!/bin/bash

# Script to start ecallmgr
echo "127.0.0.1 ecallmgr" >> /etc/hosts
# Set necessary variables
LOG_DIR="/var/log/kazoo"
LOG_FILE="${LOG_DIR}/ecallmgr.log"
HOME=/opt/kazoo
MAX_WAIT=2  # Maximum wait time in seconds

# Start ecallmgr
start() {
    echo "Starting ecallmgr..."

    # Start Kazoo (ecallmgr as part of it)
    /opt/kazoo/bin/kazoo foreground &

    # Wait for the log file to be created or touch it after MAX_WAIT seconds
    echo "Waiting for log file at ${LOG_FILE}..."
    for (( i=1; i<=MAX_WAIT; i++ )); do
        if [ -f "${LOG_FILE}" ]; then
            echo "Tailing log file at ${LOG_FILE}"
            tail -f ${LOG_FILE}
            return
        fi
        sleep 1
    done

    # If the log file doesn't exist after the wait, create it and start tailing
    echo "Log file not created by ecallmgr. Creating log file now."
    touch ${LOG_FILE}
    tail -f ${LOG_FILE}
}

# Execute start function
start