#!/bin/bash

set -euo pipefail

# Load credentials from systemd
LINODE_TOKEN=$(systemd-creds cat linode-dns-updater.token)
DOMAIN_ID=$(systemd-creds cat linode-dns-updater.domain_id)
A_RECORD_ID=$(systemd-creds cat linode-dns-updater.a_record_id)
AAAA_RECORD_ID=$(systemd-creds cat linode-dns-updater.aaaa_record_id)

# Sleep to debounce network changes
sleep 15

# Get current public IPv4 and IPv6
IPV4=$(curl -s -4 https://ipv4.icanhazip.com/ || echo "")
IPV6=$(curl -s -6 https://ipv6.icanhazip.com/ || echo "")

API_BASE="https://api.linode.com/v4/domains/${DOMAIN_ID}/records"
HEADERS="Authorization: Bearer ${LINODE_TOKEN}"

update_record() {
    local record_id=$1
    local ip_address=$2
    local record_type=$3

    if [[ -n "$ip_address" ]]; then
        curl -s -X PUT \
            -H "Content-Type: application/json" \
            -H "$HEADERS" \
            -d "{\"target\": \"$ip_address\"}" \
            "${API_BASE}/${record_id}" > /dev/null
        echo "Updated $record_type record to $ip_address"
    fi
}

# Update records
if [[ -n "$IPV4" && -n "$A_RECORD_ID" ]]; then
    update_record "$A_RECORD_ID" "$IPV4" "A"
fi

if [[ -n "$IPV6" && -n "$AAAA_RECORD_ID" ]]; then
    update_record "$AAAA_RECORD_ID" "$IPV6" "AAAA"
fi
