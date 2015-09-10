#!/bin/bash

ARRAY=( "tul.sakilu.com:/home/ubuntu/vghtpe/public/"
        "multivendor.sakilu.com:/home/ubuntu/multivendor/"
        "sqladmin.sakilu.com:/home/ubuntu/sqladmin/"
      )

for sites in "${ARRAY[@]}" ; do
    DOMAIN="${sites%%:*}"
    WEBPATH="${sites##*:}"

    . virtualhost.sh create $DOMAIN $WEBPATH
done
