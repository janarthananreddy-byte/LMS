FROM frappe/bench:latest

ARG FRAPPE_BRANCH=version-15
ARG PAYMENTS_BRANCH=version-15
ARG LMS_BRANCH=main

# Install Redis as root
USER root
RUN apt-get update && apt-get install -y redis-server && rm -rf /var/lib/apt/lists/*

USER frappe
WORKDIR /home/frappe

# Initialize bench
RUN bench init \
    --frappe-branch=${FRAPPE_BRANCH} \
    --skip-redis-config-generation \
    --skip-assets \
    frappe-bench

WORKDIR /home/frappe/frappe-bench

# Get payments app (dependency)
RUN bench get-app --branch=${PAYMENTS_BRANCH} payments

# Get LMS app from official Frappe repo
RUN bench get-app --branch=${LMS_BRANCH} lms https://github.com/frappe/lms.git

# Build assets
RUN bench build

# Copy the entrypoint script
COPY --chown=frappe:frappe entrypoint.sh /home/frappe/frappe-bench/entrypoint.sh
RUN chmod +x /home/frappe/frappe-bench/entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/home/frappe/frappe-bench/entrypoint.sh"]
