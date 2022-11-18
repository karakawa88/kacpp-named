#!/bin/bash

# NAMED_CONF_DIR
#   namedの設定ディレクトリのパス
# この環境変数は起動前に設定する(Dockerに環境変数として渡す)が
# これがsystemdでは無効化されてしまう。そのためsystemdのServiceの
# EmvironmentFileでこの環境変数を読み込む。
if [[ -n "$NAMED_CONF_DIR" ]]
then
    echo "NAMED_CONF_DIR=\"${NAMED_CONF_DIR}\"" >/etc/default/named
fi

systemctl daemon-reload
systemctl enable named
systemctl start named

exit 0

