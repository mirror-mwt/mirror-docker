FROM debian:bookworm-slim

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    cron curl jq apt-mirror dnf dnf-plugins-core rsync

# Add script files
ADD scripts/ /root/scripts/

# Add apt-mirror config
ADD apt-mirror.conf /etc/apt/mirror.list

# Add crontab file in the cron directory and set execution rights
ADD --chmod=0644 crontab /etc/cron.d/mirror-cron

# Create a log folder in /var/log
RUN install -d -m 0755 -o root -g root /var/log/mirror
