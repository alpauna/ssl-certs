#!/bin/bash
# Generate a new self-signed certificate from an existing ECC private key
# Usage: ./gen-cert.sh [key.pem] [cert.pem] [days]
#
# Prompts interactively for DNS and IP SAN entries.
# Press Enter on a blank line to move to the next section / finish.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KEY_FILE="${1:-key.pem}"
CERT_FILE="${2:-cert.pem}"
DAYS="${3:-3650}"
CONF="${SCRIPT_DIR}/openssl.cnf"

if [ ! -f "$KEY_FILE" ]; then
    echo "Error: Private key not found: $KEY_FILE"
    echo "Usage: $0 [key.pem] [cert.pem] [days]"
    exit 1
fi

if [ ! -f "$CONF" ]; then
    echo "Error: OpenSSL config not found: $CONF"
    exit 1
fi

# Collect DNS entries
dns_entries=()
echo "Enter DNS names (blank line to finish):"
while true; do
    read -rp "  DNS.$((${#dns_entries[@]} + 1)): " entry
    [ -z "$entry" ] && break
    dns_entries+=("$entry")
done

# Collect IP entries
ip_entries=()
echo "Enter IP addresses (blank line to finish):"
while true; do
    read -rp "  IP.$((${#ip_entries[@]} + 1)): " entry
    [ -z "$entry" ] && break
    ip_entries+=("$entry")
done

# Build temporary config with SAN entries appended
TMP_CONF=$(mktemp "${SCRIPT_DIR}/openssl.XXXXXX.cnf")
trap 'rm -f "$TMP_CONF"' EXIT

cp "$CONF" "$TMP_CONF"

if [ ${#dns_entries[@]} -gt 0 ] || [ ${#ip_entries[@]} -gt 0 ]; then
    echo "subjectAltName       = @alt_names" >> "$TMP_CONF"
    echo "" >> "$TMP_CONF"
    echo "[alt_names]" >> "$TMP_CONF"
    for i in "${!dns_entries[@]}"; do
        echo "DNS.$((i + 1)) = ${dns_entries[$i]}" >> "$TMP_CONF"
    done
    for i in "${!ip_entries[@]}"; do
        echo "IP.$((i + 1))  = ${ip_entries[$i]}" >> "$TMP_CONF"
    done
fi

echo
echo "Key:    $KEY_FILE"
echo "Output: $CERT_FILE"
echo "Valid:  $DAYS days"
if [ ${#dns_entries[@]} -gt 0 ]; then
    echo "DNS:    ${dns_entries[*]}"
fi
if [ ${#ip_entries[@]} -gt 0 ]; then
    echo "IP:     ${ip_entries[*]}"
fi
echo

openssl req -new -x509 \
    -key "$KEY_FILE" \
    -out "$CERT_FILE" \
    -days "$DAYS" \
    -config "$TMP_CONF" \
    -extensions v3_req

echo
echo "Certificate generated: $CERT_FILE"
echo
openssl x509 -in "$CERT_FILE" -noout -subject -dates -ext subjectAltName
