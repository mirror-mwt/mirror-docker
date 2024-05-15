FROM debian:bookworm-slim

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    cron curl jq apt-mirror dnf dnf-plugins-core rsync \
    ca-certificates bzip2

# Dnf plugins-core-workaround (hopefully unnecessary in the future)
RUN echo 'pluginpath=/usr/lib/python3/dist-packages/dnf-plugins' >> /etc/dnf/dnf.conf

# Add script files
COPY scripts/ /root/scripts/

# Add apt-mirror config
COPY etc/apt/apt-mirror.list /etc/apt/mirror.list

# Add dnf-reposync config
COPY etc/yum.repos.d/ /etc/yum.repos.d/

# Add crontab file in the cron directory and set execution rights
COPY --chmod=0644 crontab /etc/cron.d/mirror-cron

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

# Run the command on container startup
CMD printenv | grep ^MWT_ >> /etc/environment && cron && tail -f /var/log/cron.log