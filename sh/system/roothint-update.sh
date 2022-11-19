#!/bin/bash

echo "roothint情報の更新開始"

if [[ ! -d "$NAMED_CONF_DIR" ]]
then
    echo "NAMED_CONF_DIRが存在しないか定義されていません。" 1>&2
    exit 1
fi
if [[ -r "$NAMED_CONF_DIR"/named.src ]]
then
    source "$NAMED_CONF_DIR"/named.src
fi
ROOT_HINT=${ROOT_HINT:-"${NAMED_CONF_DIR}/db/named.root"}

dig @a.root-servers.net . ns > "$ROOT_HINT"
if (( $? != 0 ))
then
    echo "roothint情報を更新するのに失敗しました。 $ROOT_HINT" 1>&2
    exit 2
fi
echo "roothint情報を更新しました 。$ROOT_HINT" 1>&2

exit 0
