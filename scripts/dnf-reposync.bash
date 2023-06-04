#!/bin/bash

set -e

SCRIPT_DIR="$(dirname "$0")"
desination_path="/mirror/dnf-reposync"

####################
# Mirror
####################
/usr/bin/dnf reposync -y --repoid=shiftkey -p "$desination_path/" --download-metadata --remote-time --releasever 11
