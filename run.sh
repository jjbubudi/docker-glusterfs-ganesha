#!/bin/bash
set -e

GANESHA_LOGFILE=${GANESHA_LOGFILE-"/dev/stdout"}
GANESHA_CONFIGFILE=${GANESHA_CONFIGFILE-"/etc/ganesha/ganesha.conf"}
GANESHA_OPTIONS=${GANESHA_OPTIONS-"-N NIV_EVENT"}
GANESHA_EXPORT_ID=${GANESHA_EXPORT_ID-"1"}
GANESHA_GLUSTER_VOLUME=${GANESHA_GLUSTER_VOLUME-""}
GANESHA_GLUSTER_HOSTNAME=${GANESHA_GLUSTER_HOSTNAME-""}

function bootstrap_config() {
    if [ -z "${GANESHA_GLUSTER_VOLUME}" ]; then
        echo "GANESHA_GLUSTER_VOLUME cannot be empty"
        exit 1
    fi

    if [ -z "${GANESHA_GLUSTER_HOSTNAME}" ]; then
        echo "GANESHA_GLUSTER_HOSTNAME cannot be empty"
        exit 1
    fi
 
    echo "Bootstrapping Ganesha NFS config"
    cat <<END >${GANESHA_CONFIGFILE}

Nfs_core_param {
    Enable_NLM = false;
    Protocols = "4";
}

Nfs_krb5 {
    Active_krb5 = false;
}

Export {
    Export_Id = ${GANESHA_EXPORT_ID};
    Path = "/${GANESHA_GLUSTER_VOLUME}";
    Pseudo = "/${GANESHA_GLUSTER_VOLUME}";

    FSAL {
        name = gluster;
        hostname = "${GANESHA_GLUSTER_HOSTNAME}";
        volume = "${GANESHA_GLUSTER_VOLUME}";
    }

    Access_type = RW;
    Squash = no_root_squash;
    Disable_ACL = true;
    Protocols = "4";
    Transports = "TCP";
    SecType = "sys";
}

END
}

function bootstrap_export() {
    if [ ! -f ${GANESHA_GLUSTER_VOLUME} ]; then
        mkdir -p "/${GANESHA_GLUSTER_VOLUME}"
    fi
}

function init_rpc() {
    echo "Starting rpcbind"
    rpcbind || return 0
    rpc.idmapd || return 0
    sleep 1
}

function init_dbus() {
    echo "Starting dbus"
    rm -f /var/run/dbus/system_bus_socket
    rm -f /var/run/dbus/pid
    dbus-uuidgen --ensure
    dbus-daemon --system --fork
    sleep 1
}

bootstrap_config
bootstrap_export

init_rpc
init_dbus

echo "Starting Ganesha NFS"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib
exec /usr/bin/ganesha.nfsd -F -L ${GANESHA_LOGFILE} -f ${GANESHA_CONFIGFILE} ${GANESHA_OPTIONS}