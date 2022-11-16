# kacpp-named Bind9 DNSサーバーイメージ

## 概要
Bind9 DNSサーバーイメージ。


## バージョン
bind9のバージョンは9.18.8です。

## 使い方
```shell
# Dockerでの使い方
docker image pull kagalpandh/kacpp-named
docker run -dit --name kacpp-named kagalpandh/kacpp-named
# namedが起動しているコンテナーに一旦入る
docker exec -it kacpp-samba "/bin/bash"
# DNSサーバーの初期化スクリプト実行
/usr/local/sh/system/named-init.sh
```

## 説明
Bind 9をソースからインストールしてある。
Bindのホームは/usr/local/である。
Bind9のサーバーはsystemdで起動する。
service名はnamed.serviceである。
systemdはDockerfileで自動起動が登録されないため初期化スクリプト
/usr/local/sh/system/named-init.shを実行する必要がある。
そのまま自動起動できるがchroot環境にもできる。

## NAMED_CONF_DIR環境変数
接定ファイルを外側とマウントしたい場合はこの環境変数にディレクトリのパスを指定。
NAMED_CONF_DIR環境変数はDocker起動時に渡す環境変数でnamedの設定ファイルやDBファイルやnamed.srcファイルがあるものとみなす。

## Bindのchroot
Bind9はchroot機能を持ちもしchroot環境にしたければNAMED_ROOTを設定する。
空文字列や定義されていないとchroot環境でないとみなされる。
chrootをする場合はそのほかにNAMED_CONF_FILEを設定しNAMED_ROOTを/にした相対パスを指定する。
例えばNAMED_ROOTが/var/namedの場合/var/named/etc/namedに設定ファイルとDBファイルを外側と
マウントする場合は/etc/named/named.confをこれに設定する。

## Bind起動の環境変数
Bindを起動する環境変数にはファイルがありデフォルトは/usr/local/sh/sysconfig/namedで
ユーザーが指定指定する場合はNAMED_CONF_DIRのnamed.srcファイルに記述する。
それぞれの環境変数
<dl>
    <dt>NAMED_ROOT</dt>
    <dd>
        Bindのchroot環境のrootのパス。
        ここが空文字列かこの環境変数が定義されていないとchrootではないとみなされる。
    </dd>
    <dt>NAMED_CONF_FILE</dt>
    <dd>
        Bind9の設定ファイルのパス。
        NAMED_ROOTが設定されている場合はそこからの相対パス。
        デフォルトは/usr/local/etc/named/named.conf
    </dd>
    <dt>NAMED</dt>
    <dd>
        namedのプログラムパス。
        デフォルトは/usr/local/sbin/named。
    </dd>
    <dt>RNDC</dt>
    <dd>
        rndcのプログラムパス。
        デフォルトは/usr/local/sbin/rndc。
    </dd>
    <dt>RNDC_CONF</dt>
    <dd>
        rndcの設定ファイルのパス。
        デフォルトは/usr/local/etc/named/rndc.conf。
    </dd>
    <dt>QUERY_LOG_FLAG</dt>
    <dd>
        DNSクエリーのログをとるか指定。とるならTRUE。
        デフォルトはFALSE。
    </dd>
</dl>

# Bind9のマウントポイント
設定ファイルとDBファイルの場所を外側からマウントする必要があるが
マウントする場所は自由である。マウントするにはNAMED_CONF_DIRに起動前に環境変数を設定し
そこにマウントする。デフォルトは/usr/local/etc/namedである。

# ログ

# docker-composeでの使用
chrootで起動するとする。NAMED_ROOTは/var/namedである。
設定ファイルディレクトリは/var/named/etc/namedでここにマウントする。
named.srcファイル。
```shell
NAMED_ROOT=/var/named
NAMED_CONF=/etc/named/named.conf
RNDC_CONF=/var/named/etc/named/rndc.conf

docker-compose.yml
```shell
version: "3"

# docker run --privileged -dit --name kacpp-mail --net kaawsnet -p 25:25 -p 465:465 -p 587:587 -v /home:/home/mail_users -v /home/local_etc:/usr/local/etc kagalpandh/kacpp-mail

services:
    kacpp-named:
        image: kagalpandh/kacpp-named
        container_name: kacpp-named
        # 外側から設定ファイルをマウントする場合
        # chrootでの設定 NAMED_ROOTは/var/named
        volumes:
            - /home/local_etc/named:/var/named/etc/named
        expose:
            - "53"
            - "953"
        networks:
            - raspinet
        ports:
            - "53:53/tcp"
            - "53:53/udp"
            - "953:953/tcp"
        cap_add:
            - SYS_ADMIN
        privileged: true
#        env_file: kacpp-named.src
         environment:
             NAMED_CONF_DIR: /var/named/etc/named
networks:
    raspinet:
        external: true


```

##構成
Bind9ホーム         /usr/local/
設定ディレクトリ    /usr/local/etc/named
    設定ファイル        named.conf
    環境変数ファイル    named.src
デフォルトの環境変数ファイル    /usr/local/sh/sysconfig/named
システムスクリプト  /usr/local/sh/system
Bind9初期化スクリプト           /usr/local/sh/system/named-init.sh
サービス起動スクリプト  /usr/local/sh/init.d/named.sh
ログ                /var/log/named.log

##ベースイメージ
kagalpandh/kacpp-pydev

# その他
DockerHub: [kagalpandh/kacpp-named](https://hub.docker.com/repository/docker/kagalpandh/kacpp-named)<br />
GitHub: [karakawa88/kacpp-named](https://github.com/karakawa88/kacpp-named)

