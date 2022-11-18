#!/usr/bin/sh

# Generates your own Certificate Authority for development.
# This script should be executed just once.

set -e

SELFSIGN_INSTALL_DIR=.
CA_DAYS=1825
CERT_OPTS="-days $CA_DAYS"

if [ ! command -v openssl &> /dev/null ]; then
    echo "openssl could not be found. Please install OpenSSL and run this script after"
    exit
fi

gen_ca_cert () {
  local SETUP_OPENSSL_CNF="$SELFSIGN_INSTALL_DIR/ca/openssl.cnf"
  local SETUP_CERT_PEM_PATH="$SELFSIGN_INSTALL_DIR/ca/certs/ca.cert.pem"
  local SETUP_CERT_PKEY_PATH="$SELFSIGN_INSTALL_DIR/ca/private/ca.key.pem"

  # Generate private key
  if [ ! -f "$SETUP_CERT_PKEY_PATH" ]; then
    echo "Generating CA private key"
    openssl genrsa -out $SETUP_CERT_PKEY_PATH 4096

    chmod 400 $SETUP_CERT_PKEY_PATH
    echo "Generated CA private key"
  else
    echo "CA private key already exists"
  fi

  if [ ! -f "$SETUP_CERT_PEM_PATH" ]; then
    echo "Generating CA certificate"
    openssl req -config $SETUP_OPENSSL_CNF \
          -key $SETUP_CERT_PKEY_PATH \
          -new -x509 -sha256 \
          $CERT_OPTS \
          -out $SETUP_CERT_PEM_PATH

    chmod 444 $SETUP_CERT_PEM_PATH

    echo "Created CA certificate"
  else
    echo "CA certificate already exists"
  fi
}

gen_intermediate_cert() {
  local SETUP_CA_OPENSSL_CNF="$SELFSIGN_INSTALL_DIR/ca/openssl.cnf"
  local SETUP_OPENSSL_CNF="$SELFSIGN_INSTALL_DIR/ca/intermediate/openssl.cnf"
  local SETUP_PRIV_DIR="$SELFSIGN_INSTALL_DIR/ca/intermediate/private"
  local SETUP_CERTS_DIR="$SELFSIGN_INSTALL_DIR/ca/intermediate/certs"
  local SETUP_CSR_DIR="$SELFSIGN_INSTALL_DIR/ca/intermediate/csr"

  local SETUP_CERT_PEM_PATH="$SETUP_CERTS_DIR/intermediate.cert.pem"
  local SETUP_CERT_PKEY_PATH="$SETUP_PRIV_DIR/intermediate.key.pem"
  local SETUP_CERT_CSR_PATH="$SETUP_CSR_DIR/intermediate.csr.pem"

  # Generate private key
  if [ ! -f "$SETUP_CERT_PKEY_PATH" ]; then
    echo "Generating Intermediate CA private key"
    openssl genrsa -out $SETUP_CERT_PKEY_PATH 4096

    chmod 666 $SETUP_CERT_PKEY_PATH
    echo "Generated Intermediate CA private key"
  else
    echo "Intermediate CA private key already exists"
  fi

  if [ ! -f "$SETUP_CERT_CSR_PATH" ]; then
    echo "Generating Intermediate CA certificate signing request (CSR)"

    openssl req -config $SETUP_OPENSSL_CNF -new -sha256 \
      -extensions v3_intermediate_ca \
      -key $SETUP_CERT_PKEY_PATH \
      -out $SETUP_CERT_CSR_PATH

    echo "Generated Intermediate CA certificate signing request (CSR)"
  else
    echo "Intermediate CA certificate signing request (CSR) already exists"
  fi

  if [ ! -f "$SETUP_CERT_PEM_PATH" ]; then
    echo "Generating Intermediate CA certificate"

    openssl ca -config $SETUP_CA_OPENSSL_CNF \
          -extensions v3_intermediate_ca \
          -notext -md sha256 \
          $CERT_OPTS \
          -in $SETUP_CERT_CSR_PATH \
          -out $SETUP_CERT_PEM_PATH

    chmod 666 $SETUP_CERT_PEM_PATH

    echo "Generated Intermediate CA certificate"
  else
    echo "Intermediate CA certificate already exists"
  fi

}

gen_chain_cert () {
  local SETUP_CA_PATH="$SELFSIGN_INSTALL_DIR/ca/certs/ca.cert.pem"
  local SETUP_INTERMEDIATE_PATH="$SELFSIGN_INSTALL_DIR/ca/intermediate/certs/intermediate.cert.pem"
  local SETUP_CHAIN_CERT_PEM_PATH="$SELFSIGN_INSTALL_DIR/ca/intermediate/certs/chain.cert.pem"

  # Create the intermediate chain
  if [ -f "$SETUP_CA_PATH" ]; then
    if [ -f "$SETUP_INTERMEDIATE_PATH" ]; then
      echo "Generating chain certificate"

      if [ -f "$SETUP_CHAIN_CERT_PEM_PATH" ]; then
        chmod 666 $SETUP_CHAIN_CERT_PEM_PATH
      fi
      
      cat $SETUP_INTERMEDIATE_PATH $SETUP_CA_PATH > $SETUP_CHAIN_CERT_PEM_PATH
      chmod 666 $SETUP_CHAIN_CERT_PEM_PATH
      echo "Generated chain certificate $SETUP_CHAIN_CERT_PEM_PATH"
    else
      echo "Missing Intermediate certificate"
    fi
  else
    echo "Missing CA certificate"
  fi
}


# Verify or setup CA directory
gen_ca_cert
gen_intermediate_cert
gen_chain_cert
