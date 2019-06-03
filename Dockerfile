FROM ubuntu:18.04
LABEL maintainer="Jimmy Au<jjbubudi@gmail.com>"

RUN apt-get update && \
    apt-get install -y gnupg && \
    echo "deb http://ppa.launchpad.net/gluster/glusterfs-6/ubuntu bionic main" > /etc/apt/sources.list.d/glusterfs-6.list && \
    echo "deb http://ppa.launchpad.net/gluster/nfs-ganesha-2.7/ubuntu bionic main" > /etc/apt/sources.list.d/nfs-ganesha-2.7.list && \
    echo "deb http://ppa.launchpad.net/gluster/libntirpc-1.7/ubuntu bionic main" > /etc/apt/sources.list.d/libntirpc-1.7.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F7C73FCC930AC9F83B387A5613E01B7B3FE869A9 && \
    apt-get update && \
    apt-get install -y netbase nfs-common dbus nfs-ganesha nfs-ganesha-gluster nfs-ganesha-ceph glusterfs-common && \
    apt-get -y clean all && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    mkdir -p /run/rpcbind /var/run/dbus && \
    touch /run/rpcbind/rpcbind.xdr /run/rpcbind/portmap.xdr && \
    chmod 755 /run/rpcbind/* && \
    chown messagebus:messagebus /var/run/dbus

COPY run.sh /run.sh
EXPOSE 2049

CMD ["/run.sh"]