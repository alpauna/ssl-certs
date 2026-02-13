# ssl-certs

Interactive OpenSSL cert generator — prompts for DN fields, key size, digest, basicConstraints, and DNS/IP SANs, then signs with an existing private key.

## Usage

```bash
./gen-cert.sh [key.pem] [cert.pem] [days]
```

All arguments are optional. Defaults: `key.pem`, `cert.pem`. If `days` is omitted, no expiry (`-days`) is added to the CSR request.

### Prompts

| Prompt | Default | Notes |
|--------|---------|-------|
| Key size (default_bits) | 2048 | RSA key size |
| Message digest (default_md) | sha256 | Hash algorithm |
| Challenge password | (none) | Hidden input; blank to skip |
| Country (C) | US | 2-letter country code |
| State (ST) | Texas | State or province |
| City (L) | Dallas | City or locality |
| Organization (O) | GoodmanHP | Organization name |
| Common Name (CN) | GoodmanHP Controller | FQDN of the server |
| basicConstraints CA | (none) | TRUE, FALSE, or blank (omit entirely) |
| DNS names | (none) | Enter one per line, blank to finish |
| IP addresses | (none) | Enter one per line, blank to finish |

### Example

```
$ ./gen-cert.sh /mnt/sd/key.pem /mnt/sd/cert.pem

=== Certificate Settings ===
  Key size (default_bits) [2048]:
  Message digest (default_md) [sha256]:
  Challenge password (blank for none):

=== Distinguished Name ===
  Country (C) [US]:
  State (ST) [Texas]:
  City (L) [Dallas]:
  Organization (O) [GoodmanHP]:
  Common Name / FQDN (CN) [GoodmanHP Controller]:

=== Extensions ===
  basicConstraints CA: (TRUE/FALSE, blank for none): FALSE

=== Subject Alternative Names ===
Enter DNS names (blank line to finish):
  DNS.1: goodmanhp.local
  DNS.2:
Enter IP addresses (blank line to finish):
  IP.1: 192.168.0.100
  IP.2: 192.168.4.1
  IP.3:

=== Summary ===
Key:      /mnt/sd/key.pem
Output:   /mnt/sd/cert.pem
Valid:    (no expiry set)
Bits:     2048
Digest:   sha256
Subject:  C=US, ST=Texas, L=Dallas, O=GoodmanHP, CN=GoodmanHP Controller
CA:       FALSE
DNS:      goodmanhp.local
IP:       192.168.0.100 192.168.4.1

Certificate generated: /mnt/sd/cert.pem

subject=C=US, ST=Texas, L=Dallas, O=GoodmanHP, CN=GoodmanHP Controller
X509v3 Subject Alternative Name:
    DNS:goodmanhp.local, IP Address:192.168.0.100, IP Address:192.168.4.1
```

Press Enter to accept defaults. Blank lines skip DNS/IP sections entirely.

## Generating a new ECC P-256 key

If you don't have an existing key:

```bash
openssl ecparam -genkey -name prime256v1 -noout -out key.pem
```

## Requirements

- OpenSSL
- Bash
