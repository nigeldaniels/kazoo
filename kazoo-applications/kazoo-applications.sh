#!/bin/bash

echo "127.0.0.1 kazoo-applications" >> /etc/hosts

if [ -f /etc/default/kazoo ]; then
    . /etc/default/kazoo
fi

RETVAL=1
NAME=${KAZOO_NAME:-kazoo-applications}
USER=${KAZOO_USER:-kazoo}
BIN_FILE=${KAZOO_BIN:-/opt/kazoo/bin/kazoo}
PID_FILE=${KAZOO_PID:-/var/run/kazoo/${NAME}.pid}
export HOME=${KAZOO_ROOT:-/opt/kazoo}

if [ -f /etc/sysconfig/kazoo ]; then
    . /etc/sysconfig/kazoo
fi

if [ "${NAME}" == "kazoo-applications" ]; then
    NAME="kazoo_apps"
else
    NAME=${NAME#*-}
fi

export KAZOO_NODE="${NAME}"

# Detect core count
CORES=$(grep -E "^processor" /proc/cpuinfo | wc -l)
if [ "${CORES}" = "1" ]; then
    BEAM=beam
else
    BEAM=beam.smp
fi

prepare() {
    rm -f /etc/kazoo/core/vm*.args
    chown ${USER} /etc/kazoo/core
    chown -R ${USER} /opt/kazoo
    mkdir -p /tmp/erl_pipes/${NAME}
    chown -R ${USER} /tmp/erl_pipes/${NAME}
    mkdir -p /var/log/kazoo
    chown -R ${USER} /var/log/kazoo
    mkdir -p /var/run/kazoo
    chown -R ${USER} /var/run/kazoo
    if [ -e ${PID_FILE} ]; then
        rm -rf ${PID_FILE}
    fi
    RETVAL=$?
}

start() {
    cd ${HOME}

    if ${BIN_FILE} pid > /dev/null 2>&1; then
        echo "Kazoo ${NAME} is already running!"
        return
    fi

    export CODE_LOADING_MODE=interactive
    export ERL_CRASH_DUMP="/var/log/kazoo/$(date +%s)_${NAME}_erl_crash.dump"
    set -- ${BIN_FILE} "$@"
    exec "$@"
    RETVAL=$?

    if [ ${RETVAL} -ne 0 ]; then
        echo "Failed to start Kazoo ${NAME}!"
        RETVAL=1
    fi
}

stop() {
    for i in $(pidof ${BEAM}); do
        if cat /proc/$i/cmdline | grep -Eq "name[^\-]+${NAME}"; then
            kill $i
            RETVAL=$?
        fi
    done
}

restart() {
    stop
    start
}

status() {
    cd ${HOME}
    for i in $(pidof ${BEAM}); do
        if cat /proc/$i/cmdline | grep -Eq "name[^\-]+${NAME}"; then
            /usr/sbin/sup -n ${NAME} kz_nodes status
            RETVAL=$?
        fi
    done
    if [ ${RETVAL} -eq 1 ]; then
        echo "${NAME} is not running!"
    fi
}

connect() {
    cd ${HOME}
    for i in $(pidof ${BEAM}); do
        if cat /proc/$i/cmdline | grep -Eq "name[^\-]+${NAME}"; then
            set_cookie
            ${BIN_FILE} remote_console
            RETVAL=$?
        fi
    done
    if [ ${RETVAL} -eq 1 ]; then
        echo "${NAME} is not running!"
    fi
}

attach() {
    cd ${HOME}
    for i in $(pidof ${BEAM}); do
        if cat /proc/$i/cmdline | grep -Eq "name[^\-]+${NAME}"; then
            set_cookie
            echo "WARNING: You are now directly attached to the running ${NAME} Erlang node."
            echo "   It is safer to use: $0 connect"
            ${BIN_FILE} attach
            RETVAL=$?
        fi
    done
    if [ ${RETVAL} -eq 1 ]; then
        echo "${NAME} is not running!"
    fi
}

ping_node() {
    cd ${HOME}
    for i in $(pidof ${BEAM}); do
        if cat /proc/$i/cmdline | grep -Eq "name[^\-]+${NAME}"; then
            set_cookie
            ${BIN_FILE} ping
            RETVAL=$?
        fi
    done
    if [ ${RETVAL} -eq 1 ]; then
        echo "${NAME} is not running!"
    fi
}

pid() {
    cd ${HOME}
    for i in $(pidof ${BEAM}); do
        if cat /proc/$i/cmdline | grep -Eq "name[^\-]+${NAME}"; then
            echo $i
            RETVAL=0
        fi
    done
    if [ ${RETVAL} -eq 1 ]; then
         echo "${NAME} is not running!"
    fi
}

set_cookie() {
    export KAZOO_COOKIE=$(/usr/sbin/sup -n ${NAME} erlang get_cookie | sed "s|'||g")
    RETVAL=$?
}

case "$1" in
    prepare)
        prepare
        ;;
    background)
        start "start"
        ;;
    start)
        start "foreground"
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    connect)
        connect
        ;;
    attach)
        attach
        ;;
    ping)
        ping_node
        ;;
    pid)
        pid
        ;;
    *)
        echo "Usage: $0 (prepare|start|background|stop|restart|status|connect|attach|ping|pid)"
esac

exit ${RETVAL}
