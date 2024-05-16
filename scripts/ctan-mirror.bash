#!/bin/bash

set -e

MIRROR_URL="mirror.mwt.me/ctan"

destination_path="/mirror/tex-archive"

# Create a tempfile
#
TMPFILE1=$(mktemp /tmp/ctan.XXXXXX)
TMPFILE2=$(mktemp /tmp/ctan.XXXXXX)

####################
# Mirror
####################
rsync -ai --filter 'protect .stfolder' --log-file="$TMPFILE1" --delete rsync://rsync.dante.ctan.org/CTAN "$destination_path"

####################
# CDN Purge
####################

if [ -n "$MWT_CLOUDFLARE_TOKEN" ]; then
	# Purge the CDN using values from rsync log
	grep -E '\] (>f\.|cLc\.t)' "$TMPFILE1" | cut -d \  -f 5 | while mapfile -t -n 30 ary && ((${#ary[@]})); do
		printf '%s\n' "${ary[@]}" | jq -R . | jq -s "{ \"files\" : map(\"https://${MIRROR_URL}/\" + .) }" | tee "$TMPFILE2"
		curl -H "Content-Type:application/json" -H "Authorization: Bearer ${MWT_CLOUDFLARE_TOKEN}" -d "@$TMPFILE2" "https://api.cloudflare.com/client/v4/zones/7344a2687b9c922e211744794188f6e7/purge_cache"
		echo ""
	done
fi

####################
# Cleanup
####################

# Remove the tempfiles
rm -f "$TMPFILE1"
rm -f "$TMPFILE2"
