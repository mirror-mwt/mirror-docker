#!/bin/bash

set -e

MIRROR_URL="mirror.mwt.me/termux"

SCRIPT_DIR="$(dirname "$0")"
destination_path="/mirror/termux"

# Create a tempfile
#
TMPFILE1=$(mktemp /tmp/termux-mirror.XXXXXX)
TMPFILE2=$(mktemp /tmp/termux-mirror.XXXXXX)

####################
# Mirror
####################
RSYNC_PASSWORD=termuxmirror rsync -ai --delete --exclude termux-main-21 --log-file=$TMPFILE1 rsync@grimler.se::termux "$destination_path"

####################
# CDN Purge
####################

# Purge the CDN using values from rsync log
if [ -n "$MWT_CLOUDFLARE_TOKEN" ]; then
    cat $TMPFILE1 | grep -E '\] (>f\.|cLc\.t)' | cut -d \  -f 5 |
        sed \
            -e "s|^termux-main|main|" \
            -e "s|^termux-root|root|" \
            -e "s|^termux-x11|x11|" |
        while mapfile -t -n 30 ary && ((${#ary[@]})); do
            printf '%s\n' "${ary[@]}" | jq -R . | jq -s "{ \"files\" : map(\"https://${MIRROR_URL}/\" + .) }" | tee "$TMPFILE2"
            curl -H "Content-Type:application/json" -H "Authorization: Bearer ${MWT_CLOUDFLARE_TOKEN}" -d "@$TMPFILE2" "https://api.cloudflare.com/client/v4/zones/7344a2687b9c922e211744794188f6e7/purge_cache"
            echo ""
        done
fi

####################
# Cleanup
####################

# Remove the tempfiles
rm -f $TMPFILE1
rm -f $TMPFILE2
