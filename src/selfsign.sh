#!/usr/bin/env bash

# Generates your own Certificate Authority for development.
# This script should be executed just once.

set -e

CERT_DAYS=1000
SILENT=false
CLEAN_CONFIGS=false
HAS_CONFIGS=false

while [ $# -gt 0 ]; do
    if [[ $1 == "--"* ]]; then
      v="${1/--/}"
      case $v in
        "days") CERT_DAYS=$2
        ;;
        "silent") SILENT=true
        ;;
        "domain") DOMAIN=$2
        ;;
        "path") DOMAIN_PATH=$2
        ;;
        "clean") CLEAN_CONFIGS=true
        ;;
        *) echo "Invalid option --$v"
        exit 1
        ;;
      esac
    elif [[ $1 == "-n="* ]]; then
      CERT_DAYS="${1/-n=/}"
    elif [[ $1 == "-s" ]]; then
      SILENT=true
    elif [[ $1 == "-d="* ]]; then
      DOMAIN="${1/-d=/}"
    elif [[ $1 == "-p="* ]]; then
      DOMAIN_PATH="${1/-p=/}"
    elif [[ $1 == "-z" ]]; then
      CLEAN_CONFIGS=true
    elif [[ $1 != '-'* ]]; then
      DOMAIN=$1
    fi

    shift
done

if [ -z "$DOMAIN" ]; then
    echo "mMissing domain name!"
    echo
    echo "Usage: $0 example.com [-d=example.com | --domain example.com] [--days DAYS | -n=DAYS] [-p=output_dir | --path output_dir] [-s | --silent]"
    echo
    echo "This will generate a wildcard certificate for the given domain name and its subdomains."
    exit
fi

if [ -z "$DOMAIN_PATH" ]; then
  DOMAIN_PATH="$DOMAIN"
fi

echo "Running cert generation script with the following options:"
echo " - validity period: ${CERT_DAYS} days"
echo " - silent: $SILENT"
echo " - domain: $DOMAIN (and *.$DOMAIN)"
echo " - output dir: $DOMAIN_PATH"

SELFSIGN_INSTALL_DIR=~/.selfsign
CA_DIR="$SELFSIGN_INSTALL_DIR/ca"
INTERMEDIATE_DIR="$CA_DIR/intermediate"
INTERMEDIATE_OPENSSL_CNF="$INTERMEDIATE_DIR/openssl.cnf"
SRC_CHAIN_PEM="$INTERMEDIATE_DIR/certs/chain.cert.pem"
INTERMEDIATE_CERT_PEM="$INTERMEDIATE_DIR/certs/intermediate.cert.pem"
INTERMEDIATE_KEY_PEM="$INTERMEDIATE_DIR/private/intermediate.key.pem"

LOCAL_CNF="$DOMAIN_PATH/openssl.cnf"
LOCAL_EXT="$DOMAIN_PATH/openssl.ext"
CERT_CSR_PEM="$DOMAIN_PATH/cert.csr"
CERT_PEM="$DOMAIN_PATH/cert.pem"
CHAIN_PEM="$DOMAIN_PATH/chain.pem"
FULLCHAIN_PEM="$DOMAIN_PATH/fullchain.pem"
PRIVKEY_PEM="$DOMAIN_PATH/privkey.pem"

if [ ! command -v openssl &> /dev/null ]; then
    echo "openssl could not be found. Please install OpenSSL and run this script after"
    exit
fi

# Verify or setup install directory
if [ ! -d "$SELFSIGN_INSTALL_DIR" ]; then
  echo "Install directory not found \"$SELFSIGN_INSTALL_DIR\". Please run setup first"
  exit 1
else
  echo "Install directory \"$SELFSIGN_INSTALL_DIR\" exists"
fi

if [ ! -d "$DOMAIN_PATH" ]; then
  echo "Domain directory \"$DOMAIN_PATH\" does not exist. Creating..."
  mkdir "$DOMAIN_PATH"
  echo "Created domain directory \"$DOMAIN_PATH\""
else
  echo "Domain directory \"$DOMAIN_PATH\" exists"
fi

create_local_cnf () {
  local CNF_PATH=$1
  local CNF_DOMAIN=$2

  cat > $CNF_PATH << EOF
[req]
default_md = sha256
default_days = 365
# prompt = no
distinguished_name = req_distinguished_name
req_extension = server_cert

[req_distinguished_name]
countryName           = Country Name (2 letter code)
stateOrProvinceName   = State or Province Name
localityName          = Locality Name
0.organizationName    = Organization Name
organizationalUnitName = Organizational Unit Name
commonName             = Common Name
emailAddress           = Email Address
commonName_default     = $CNF_DOMAIN

[server_cert]
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $CNF_DOMAIN
DNS.2 = *.$CNF_DOMAIN
EOF
}

create_local_ext () {
  local EXT_PATH=$1
  local EXT_DOMAIN=$2

  cat > "$EXT_PATH" << EOF
[server_cert]
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $EXT_DOMAIN
DNS.2 = *.$EXT_DOMAIN
EOF
}


# Generate a private key
if [ ! -f "$PRIVKEY_PEM" ]; then
  echo "Generating new certificate private key"
  openssl genrsa -out $PRIVKEY_PEM 2048
  chmod 400 $PRIVKEY_PEM
  echo "Generated certificate private key"
else
  echo "Found certificate private key"
fi




if [ ! -f "$INTERMEDIATE_CERT_PEM" ]; then
  echo "Could not find CA cert \"$INTERMEDIATE_CERT_PEM\""
  echo "Please run setup first"
  exit 1
fi

if [ ! -f "$INTERMEDIATE_KEY_PEM" ]; then
  echo "Could not find CA key \"$INTERMEDIATE_KEY_PEM\""
  echo "Please run setup first"
  exit 1
fi

if [ ! -f "$CERT_PEM" ]; then

  if [ ! -f "$CERT_CSR_PEM" ]; then

    if [ ! -f "$LOCAL_CNF" ]; then
      echo "Setting up the domain config"
      create_local_cnf $LOCAL_CNF $DOMAIN
      echo "Created the local domain config"
    else
      echo "Found local openssl config"
    fi

    echo "Creating a new certificate sign request (CSR)"

    # Create a certificate signing request
    openssl req \
        -new \
        -nodes \
        -config $LOCAL_CNF \
        -extensions server_cert \
        -key $PRIVKEY_PEM \
        -out $CERT_CSR_PEM 

    echo "Created local certificate sign request (CSR)"
  else
    echo "Found local certficiate sign request (CSR)"
  fi

  if [ ! -f "$LOCAL_EXT" ]; then
    echo "Setting up the domain extension"
    create_local_ext $LOCAL_EXT $DOMAIN
    echo "Created the domain extension"
  else
    echo "Found local domain extension config"
  fi

  echo "Generating a new domain certificate"

  openssl x509 \
    -req \
    -extfile "$LOCAL_EXT" \
    -extensions server_cert \
    -CA $INTERMEDIATE_CERT_PEM \
    -CAkey $INTERMEDIATE_KEY_PEM \
    -CAcreateserial \
    -in $CERT_CSR_PEM \
    -out $CERT_PEM \
    -days $CERT_DAYS \
    -sha256

  echo "Generated the new domain certificate"
else
  echo "Found domain certificate"
fi


if [ -f "$CERT_PEM" ]; then
  echo "Copying certificate to fullchain.pem"
  cat $CERT_PEM > $FULLCHAIN_PEM
  echo "Copied certificate to fullchain.pem"
fi

if [ -f "$CHAIN_PEM" ]; then
  echo "Copying chain to fullchain"
  cat $CHAIN_PEM >> $FULLCHAIN_PEM
  echo "Copied chain to fullchain"
else
  echo "Chain certificate not found in local dir"
  if [ -f "$SRC_CHAIN_PEM" ]; then
    echo "Chain certificate found in install dir. Copying..."
    cp $SRC_CHAIN_PEM $CHAIN_PEM
    echo "Chain certificate copied to local dir"
    cat $CHAIN_PEM >> $FULLCHAIN_PEM
    echo "Copied chain to fullchain"
  else
    echo "Could not find chain certificate \"$SRC_CHAIN_PEM\""
    echo "Please run setup if you want to include it in the fullchain certificate"
  fi
fi

clean_configs () {
  if [ -f "$LOCAL_EXT" ]; then
    rm $LOCAL_EXT
  fi
  if [ -f "$LOCAL_CNF" ]; then
    rm $LOCAL_CNF
  fi
  if [ -f "$CERT_CSR_PEM" ]; then
    rm $CERT_CSR_PEM
  fi
}

if [ -f "$LOCAL_EXT" ] || [ -f "$LOCAL_CNF" ] || [ -f "$_CERT_CSR_PEM" ]; then
  HAS_CONFIGS=true
fi

if $HAS_CONFIGS; then
  if [ "$CLEAN_CONFIGS" = false ] && [ "$SILENT" = false ]; then
    read -p "Do you want to clean configs? (yes/no) " -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        CLEAN_CONFIGS=true
    fi
  fi

  if $CLEAN_CONFIGS; then
    clean_configs
  fi
fi

echo "Complete!"
