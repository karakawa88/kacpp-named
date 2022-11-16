# bind DNSサーバーのdebianイメージ
# 日本語化も設定済み
FROM        kagalpandh/kacpp-gccdev AS builder
SHELL       [ "/bin/bash", "-c" ]
WORKDIR     /root
ENV         DEBIAN_FORONTEND=noninteractive
#https://downloads.isc.org/isc/bind9/9.18.8/bind-9.18.8.tar.xz
ENV         NAMED_VERSION=9.18.8
ENV         NAMED_DEST=bind-${NAMED_VERSION}
ENV         NAMED_SRC_FILE=${NAMED_DEST}.tar.xz
ENV         NAMED_URL="https://downloads.isc.org/isc/bind9/${NAMED_VERSION}/${NAMED_SRC_FILE}"
ENV         NAMED_GPG_PUBKEY="named-pubkey.asc"
ENV         NAMED_GPG_PUBKEY_URL="https://www.isc.org/202122pgpkey/"
ENV         NAMED_HOME=/usr/local/${NAMED_DEST}
COPY        sh/apt-install  /usr/local/sh/apt-install
# 開発環境インストール
RUN         apt update && \
                /usr/local/sh/system/apt-install.sh install named-dev.txt && \
            pip3 install $(cat /usr/local/sh/pip3/named.txt | xargs)
RUN         wget ${NAMED_URL} && wget ${NAMED_URL}.asc && \
                python3 /usr/local/sh/python/fetch_gpg_pub_key.py "${NAMED_GPG_PUBKEY_URL}" \
                    "section.section pre code" >${NAMED_GPG_PUBKEY} && \
#           GPG verify
                gpg --import ${NAMED_GPG_PUBKEY} && \
                gpg ${NAMED_SRC_FILE}.asc && \
#           named build
            tar -Jxvf ${NAMED_SRC_FILE} && cd ${NAMED_DEST} && \
                ./configure --prefix=/usr/local/${NAMED_DEST} && \
                make && make install && \
                apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/*
FROM        kagalpandh/kacpp-pydev
SHELL       [ "/bin/bash", "-c" ]
WORKDIR     /root
ENV         NAMED_VERSION=9.18.8
ENV         NAMED_DEST=bind-${NAMED_VERSION}
ENV         NAMED_ROOT=/var/named
# namedのユーザー・グループ
ENV         NAMED_USER=named
ENV         NAMED_UID=983
ENV         NAMED_GROUP=named
ENV         NAMED_GID=145
COPY        --from=builder  /usr/local/${NAMED_DEST}/ /usr/local/
COPY        sh/apt-install/named.txt /usr/local/sh/apt-install
RUN         apt update && \
            /usr/local/sh/system/apt-install.sh install named.txt && \
            groupadd -g ${NAMED_GID} ${NAMED_GROUP} && \
            useradd -s /bin/false -d /dev/null -g ${NAMED_GROUP} -G ${NAMED_GROUP} \
                -u ${NAMED_UID} ${NAMED_USER} && \
            mkdir /usr/local/sh/sysconfig && \
            mkdir "${NAMED_ROOT}" && chmod 770 ${NAMED_ROOT} && \
            cd ${NAMED_ROOT} && \
            mkdir dev && mkdir -p etc/named && mkdir -p var/run/named && mkdir -p var/log && \
            cd dev && mknod null c 1 3 && mknod random c 1 8 && \
            cd ../etc && ln -s  /etc/localtime localtime && \
            chown -R named.named ${NAMED_ROOT} && \
            find ${NAMED_ROOT} -type d -exec chmod 770 {} \; && \
            find ${NAMED_ROOT} -type f -exec chmod 640 {} \; && \
            ldconfig
COPY        sh/init.d/ /usr/local/sh/init.d
COPY        sh/sysconfig/   /usr/local/sh/sysconfig
COPY        etc/systemd/system/  /etc/systemd/system
COPY        sh/system/  /usr/local/sh/system
            # systemd
#VOLUME [ "/sys/fs/cgroup" ]
# systemdのインストールと設定
RUN         apt install -y systemd && \
            chmod 775 /usr/local/sh/system && \
            chmod 775 /usr/local/sh/init.d && \
            chown root /usr/local/sh/system/*.sh && \
            find /usr/local/sh/ -type f -name "*.sh" -exec chmod 775 {} \; && \
            # メールサーバーexim4が何故かインストールされるのでアンインストール
            #apt remove --purge exim4-base && \
            (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
            systemd-tmpfiles-setup.service ] || rm -f $i; done); \
            rm -f /lib/systemd/system/multi-user.target.wants/*;\
            rm -f /etc/systemd/system/*.wants/*;\
            rm -f /lib/systemd/system/local-fs.target.wants/*; \
            rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
            rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
            rm -f /lib/systemd/system/basic.target.wants/*;\
            rm -f /lib/systemd/system/anaconda.target.wants/* && \
            cd ~/ && apt clean && rm -rf /var/lib/apt/lists/*
# cronとlogrotateの設定
# COPY        etc/cron.d/     /etc/cron.d
# COPY        etc/logrotate.d/     /etc/logrotate.d
ENTRYPOINT  ["/usr/local/sh/system/named-entrypoint.sh"]
