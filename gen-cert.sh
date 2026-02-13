#!/bin/bash
# Generate a new self-signed certificate from an existing ECC private key
# Usage: ./gen-cert.sh [key.pem] [cert.pem] [days]
#
# Prompts interactively for all certificate fields, SAN entries, and extensions.
# Press Enter to accept defaults shown in [brackets].

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KEY_FILE="${1:-key.pem}"
CERT_FILE_ARG="${2:-}"
DAYS="${3:-}"

if [ ! -f "$KEY_FILE" ]; then
    echo "Error: Private key not found: $KEY_FILE"
    echo "Usage: $0 [key.pem] [cert.pem] [days]"
    exit 1
fi

# --- Certificate fields ---
echo "=== Certificate Settings ==="
read -rp "  Key size (default_bits) [2048]: " cfg_bits
cfg_bits="${cfg_bits:-2048}"

read -rp "  Message digest (default_md) [sha256]: " cfg_md
cfg_md="${cfg_md:-sha256}"

read -rsp "  Challenge password (blank for none): " cfg_password
echo
cfg_prompt="no"
if [ -n "$cfg_password" ]; then
    cfg_prompt="yes"
fi

echo
echo "=== Distinguished Name ==="
read -rp "  Country (C) [US]: " dn_c
dn_c="${dn_c:-US}"

read -rp "  State (ST) [Texas]: " dn_st
dn_st="${dn_st:-Texas}"

read -rp "  City (L) [Dallas]: " dn_l
dn_l="${dn_l:-Dallas}"

read -rp "  Organization (O) [GoodmanHP]: " dn_o
dn_o="${dn_o:-GoodmanHP}"

read -rp "  Common Name / FQDN (CN) [GoodmanHP Controller]: " dn_cn
dn_cn="${dn_cn:-GoodmanHP Controller}"

read -rp "  Email (blank to omit): " dn_email

# CSR filename — default to CN with spaces replaced by underscores
csr_default="${dn_cn// /_}.csr"
read -rp "  CSR filename [${csr_default}]: " csr_file
csr_file="${csr_file:-$csr_default}"

# Self-signed cert — default from CLI arg or CN-based, "none" to skip
cert_default="${CERT_FILE_ARG:-${dn_cn// /_}.pem}"
read -rp "  Certificate filename (\"none\" to skip) [${cert_default}]: " CERT_FILE
CERT_FILE="${CERT_FILE:-$cert_default}"
if [ "$CERT_FILE" = "none" ]; then
    CERT_FILE=""
fi

# Config filename — default to CN with spaces replaced by underscores
conf_default="${dn_cn// /_}.conf"
read -rp "  Config filename [${conf_default}]: " CONF_FILE
CONF_FILE="${CONF_FILE:-$conf_default}"

echo
echo "=== Extensions ==="
read -rp "  basicConstraints CA: (TRUE/FALSE, blank for none): " cfg_ca
if [ -n "$cfg_ca" ]; then
    cfg_ca=$(echo "$cfg_ca" | tr '[:lower:]' '[:upper:]')
fi

# --- SAN entries ---
echo
echo "=== Subject Alternative Names ==="
dns_entries=()
echo "Enter DNS names (blank line to finish):"
while true; do
    read -rp "  DNS.$((${#dns_entries[@]} + 1)): " entry
    [ -z "$entry" ] && break
    dns_entries+=("$entry")
done

ip_entries=()
echo "Enter IP addresses (blank line to finish):"
while true; do
    read -rp "  IP.$((${#ip_entries[@]} + 1)): " entry
    [ -z "$entry" ] && break
    ip_entries+=("$entry")
done

# Temp config for openssl (cleaned up on exit)
TMP_CONF=$(mktemp "${SCRIPT_DIR}/openssl.XXXXXX.cnf")
trap 'rm -f "$TMP_CONF"' EXIT

cat > "$TMP_CONF" <<CONF
[req]
default_bits       = ${cfg_bits}
prompt             = ${cfg_prompt}
default_md         = ${cfg_md}
distinguished_name = dn
x509_extensions    = v3_req

[dn]
C  = ${dn_c}
ST = ${dn_st}
L  = ${dn_l}
O  = ${dn_o}
CN = ${dn_cn}
CONF

if [ -n "$dn_email" ]; then
    echo "emailAddress = ${dn_email}" >> "$TMP_CONF"
fi

if [ "$cfg_prompt" = "yes" ]; then
    cat >> "$TMP_CONF" <<'CONF'
challengePassword = A challenge password

CONF
fi

echo "" >> "$TMP_CONF"
echo "[v3_req]" >> "$TMP_CONF"
if [ -n "$cfg_ca" ]; then
    echo "basicConstraints     = CA:${cfg_ca}" >> "$TMP_CONF"
fi
echo "keyUsage             = digitalSignature, keyEncipherment" >> "$TMP_CONF"
echo "extendedKeyUsage     = serverAuth" >> "$TMP_CONF"

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

# Save permanent config file
cp "$TMP_CONF" "$CONF_FILE"

# --- Summary ---
echo
echo "=== Summary ==="
echo "Key:      $KEY_FILE"
echo "Config:   $CONF_FILE"
echo "CSR:      $csr_file"
if [ -n "$CERT_FILE" ]; then
    echo "Cert:     $CERT_FILE"
    if [ -n "$DAYS" ]; then
        echo "Valid:    $DAYS days"
    else
        echo "Valid:    (no expiry set)"
    fi
else
    echo "Cert:     (skipped)"
fi
echo "Bits:     $cfg_bits"
echo "Digest:   $cfg_md"
if [ -n "$dn_email" ]; then
    echo "Subject:  C=$dn_c, ST=$dn_st, L=$dn_l, O=$dn_o, CN=$dn_cn, emailAddress=$dn_email"
else
    echo "Subject:  C=$dn_c, ST=$dn_st, L=$dn_l, O=$dn_o, CN=$dn_cn"
fi
if [ -n "$cfg_ca" ]; then
    echo "CA:       $cfg_ca"
else
    echo "CA:       (omitted)"
fi
if [ ${#dns_entries[@]} -gt 0 ]; then
    echo "DNS:      ${dns_entries[*]}"
fi
if [ ${#ip_entries[@]} -gt 0 ]; then
    echo "IP:       ${ip_entries[*]}"
fi
echo

# Generate CSR
openssl req -new \
    -key "$KEY_FILE" \
    -out "$csr_file" \
    -config "$TMP_CONF"

echo
echo "Config saved: $CONF_FILE"
echo "CSR generated: $csr_file"
echo
echo "To regenerate the CSR from the saved config:"
echo "  openssl req -out $csr_file -key $KEY_FILE -config $CONF_FILE -new"

# Self-sign the CSR if cert path was provided
if [ -n "$CERT_FILE" ]; then
    DAYS_ARG=()
    if [ -n "$DAYS" ]; then
        DAYS_ARG=(-days "$DAYS")
    fi

    openssl x509 -req \
        -in "$csr_file" \
        -signkey "$KEY_FILE" \
        "${DAYS_ARG[@]}" \
        -extfile "$TMP_CONF" \
        -extensions v3_req \
        -out "$CERT_FILE"

    echo
    echo "Certificate generated: $CERT_FILE"
    echo
    openssl x509 -in "$CERT_FILE" -noout -subject -dates -ext subjectAltName 2>/dev/null || \
    openssl x509 -in "$CERT_FILE" -noout -subject -dates
fi
