#!/bin/bash

set -e

MIRROR_URL="mirror.mwt.me"

desination_path="/mirror/apt-mirror"
mirror_path="/mirror/apt-mirror/mirror"

# Create a tempfile
#
TMPFILE=$(mktemp /tmp/apt-mirror.XXXXXX)

####################
# Mirror
####################
# clean before we mirror (clean deletes InRelease)
if [ -f "$desination_path/var/clean.sh" ]; then
	"$desination_path/var/clean.sh"
fi
# mirror
apt-mirror
# download missing InRelease file
wget -qNP "$mirror_path/zotero.retorque.re/file/apt-package-archive" "https://zotero.retorque.re/file/apt-package-archive/InRelease"

####################
# CDN Purge
####################
if [ -n "$MWT_CLOUDFLARE_TOKEN" ]; then
	find "$mirror_path" -type f -regex '.*Release\|.*Packages\.?[^/]*' -mmin -360 -print | sed \
		-e "s|^${mirror_path}/apt.packages.shiftkey.dev/ubuntu|shiftkey-desktop/deb|" \
		-e "s|^${mirror_path}/zotero.retorque.re/file/apt-package-archive|zotero/deb|" |
		while mapfile -t -n 30 ary && ((${#ary[@]})); do
			printf '%s\n' "${ary[@]}" | jq -R . | jq -s "{ \"files\" : map(\"https://${MIRROR_URL}/\" + .) }" | tee "$TMPFILE"
			curl -H "Content-Type:application/json" -H "Authorization: Bearer ${MWT_CLOUDFLARE_TOKEN}" -d "@$TMPFILE" "https://api.cloudflare.com/client/v4/zones/7344a2687b9c922e211744794188f6e7/purge_cache"
			echo ""
		done
fi

####################
# Cleanup
####################

# Remove the tempfiles
rm -f "$TMPFILE"
