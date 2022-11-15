#!/bin/bash

##########################################
# Bind 9 DNSサーバー named 起動スクリプト
#
#
# 引数
# $1    start       起動
#       stop        停止
#       restart     再起動
#       reload      設定ファイル再読込
#       status      status表示
#       help        使い方
#
# 終了ステータス
#   0   通常終了
#   1   起動や停止が失敗
#   2   引数エラー 環境変数指定エラー
#   4   インターネットに接続していない

# named起動オプション
# named環境変数ファイル
if [[ -r /usr/local/sh/sysconfig/named ]]; then
    . /usr/local/sh/sysconfig/named
fi

# NAMEの設定ファイル
NAMED_CONF_FILE=${NAMED_CONF_FILE:-"/etc/named.conf"}
# NAMEユーザーID
NAMED_USER=${NAMED_USER:-"named"}
# named chrootルートディレクトリー
#NAMED_ROOT="/home/data/raspilocal/var/named"
NAMED_ROOT=${NAMED_ROOT:-""}
# named オプション
OPTIONS=" -c $NAMED_CONF_FILE -u $NAMED_USER "
# NAMED_ROOT環境変数が設定されていないか空文字列の場合は
# chrrotをかけずNAMED_ROOT環境変数のディレクトリー名が存在すれば
# namedのオプションにそれを追加する。
if [[ -n "$NAMED_ROOT" ]]; then
    if [[ -d "$NAMED_ROOT" ]]; then
        OPTIONS="$OPTIONS -t $NAMED_ROOT"
    else
        echo "Error chroot rootディレクトリー $NAMED_ROOT が存在しません。" 1>&2
        exit 2
    fi
fi
echo $OPTIONS

# namedサーバー
NAMED=${NAMED:-"/usr/local/sbin/named"}
# rndc コマンド
RNDC=${RNDC:-"/usr/local/sbin/rndc"}
# rndc 設定ファイル
RNDC_CONF=${RNDC_CONF:-"$NAMED_ROOT/etc/rndc.conf"}
# querylogを取るかのフラグ
QUERY_LOG_FLAG=${QUERY_LOG_FLAG:-"FALSE"}
# help文字列 
USAGE_STRING="usage: named.sh [start | reload | stop | status ]"

if [[ -r /usr/local/sh/init.d/initrc ]]; then
    . /usr/local/sh/init.d/initrc
fi

_start() {
    $NAMED $OPTIONS
    if [ $? -ne 0 ]; then
        echo "Error NAMED start error!!" 2>&1
        return 1
    fi
    if [ "$QUERY_LOG_FLAG" = "FALSE" ]; then
        $RNDC -c $RNDC_CONF querylog
    fi
    return 0;
}
_reload() {
    $RNDC -c $RNDC_CONF reload
    if [ $? -ne 0 ]; then
        return 1
    fi
    return 0;
}
_stop() {
    $RNDC -c $RNDC_CONF stop
    if [ $? -ne 0 ]; then
        echo "Error named stop error!!" 2>&1
        return 1
    fi
    return 0;
}
_status() {
    $RNDC -c $RNDC_CONF status
    if [ $? -ne 0 ]; then
        echo "Error named status error!!" 2>&1
        return 1
    fi
    return 0;
}

case $1 in
    start)
        is_online -c 100 -w 1
        if [ $? -ne 0  ]; then
            echo "Error: named インターネットに接続されていません。" 1>&2
            exit 4
        fi
        _start
        ;;
    reload)
        _reload
        ;;
    stop)
        _stop
        ;;
    restart)
        _stop
        sleep 1
        _start
        ;;
    status)
        _status
        ;;
    help)
        echo $USAGE_STRING
        exit 0
        ;;
    *)
        echo "Error invalid arguments $1" 1>&2
        echo "$USAGE_STRING" 1>&2
        exit 2
        ;;
esac

if [ $? -ne 0 ]; then
    exit 1
fi

exit 0


