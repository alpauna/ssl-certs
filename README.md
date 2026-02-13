# ssl-certs

Interactive OpenSSL cert generator for ESP32 HTTPS. Prompts for DNS and IP Subject Alternative Names, then generates a self-signed certificate from an existing private key.

## Files

| File | Purpose |
|------|---------|
| `gen-cert.sh` | Interactive script that collects SANs and generates the certificate |
| `openssl.cnf` | Base OpenSSL config template (distinguished name, extensions) |

## Usage

```bash
./gen-cert.sh [key.pem] [cert.pem] [days]
```

All arguments are optional and default to `key.pem`, `cert.pem`, and `3650` (10 years).

### Example

```
$ ./gen-cert.sh /mnt/sd/key.pem /mnt/sd/cert.pem

Enter DNS names (blank line to finish):
  DNS.1: goodmanhp.local
  DNS.2:

Enter IP addresses (blank line to finish):
  IP.1: 192.168.0.100
  IP.2: 192.168.4.1
  IP.3:

Key:    /mnt/sd/key.pem
Output: /mnt/sd/cert.pem
Valid:  3650 days
DNS:    goodmanhp.local
IP:     192.168.0.100 192.168.4.1

Certificate generated: /mnt/sd/cert.pem

subject=C=US, ST=Texas, L=Dallas, O=GoodmanHP, CN=GoodmanHP Controller
notBefore=Feb 13 12:00:00 2026 GMT
notAfter=Feb 11 12:00:00 2036 GMT
X509v3 Subject Alternative Name:
    DNS:goodmanhp.local, IP Address:192.168.0.100, IP Address:192.168.4.1
```

Press Enter on a blank line to skip a section entirely. If no DNS or IP entries are provided, the certificate is generated without a Subject Alternative Name extension.

## Generating a new ECC P-256 key

If you don't have an existing key:

```bash
openssl ecparam -genkey -name prime256v1 -noout -out key.pem
```

## Customizing the subject

Edit `openssl.cnf` to change the distinguished name fields (country, state, org, common name).

## Requirements

- OpenSSL
- Bash
