#!/usr/bin/env bash

# Generates your own Certificate Authority for development.
# This script should be executed just once.

set -e

INSTALL_DIR=~/.selfsign
CA_DIR="$INSTALL_DIR/ca"
INTERMEDIATE_DIR="$CA_DIR/intermediate"
CA_DAYS=1825

if [ ! command -v openssl &> /dev/null ]; then
    echo "openssl could not be found. Please install OpenSSL and run this script after"
    exit
fi

# Verify or setup install directory
if [ ! -d "$INSTALL_DIR" ]; then
  echo "Install directory \"$INSTALL_DIR\" does not exist. Creating..."
  mkdir "$INSTALL_DIR"
  echo "Created install directory \"$INSTALL_DIR\""
else
  echo "Install directory \"$INSTALL_DIR\" exists"
fi


setup_ca_paths () {
  local SRC_OPENSSL_CNF=$1
  local SETUP_PATH=$2

  if [ ! ${SETUP_OPENSSL_CNF+"false"} ]; then
    local SETUP_OPENSSL_CNF="$SETUP_PATH/openssl.cnf"
  fi
  if [ ! ${SETUP_PRIV_DIR+"false"} ]; then
    local SETUP_PRIV_DIR="$SETUP_PATH/private"
  fi
  if [ ! ${SETUP_CERTS_DIR+"false"} ]; then
    local SETUP_CERTS_DIR="$SETUP_PATH/certs"
  fi
  if [ ! ${SETUP_NEWCERTS_DIR+"false"} ]; then
    local SETUP_NEWCERTS_DIR="$SETUP_PATH/newcerts"
  fi
  if [ ! ${SETUP_CRL_DIR+"false"} ]; then
    local SETUP_CRL_DIR="$SETUP_PATH/crl"
  fi
  if [ ! ${SETUP_CSR_DIR+"false"} ]; then
    local SETUP_CSR_DIR="$SETUP_PATH/csr"
  fi

  # Verify or setup CA directory
  if [ ! -d "$SETUP_PATH" ]; then
    echo "CA directory does not exist. Creating..."
    mkdir "$SETUP_PATH"
    echo "Created CA directory"
  else
    echo "CA directory exists"
  fi

  # Verify or copy CA openssl.cnf
  if [ ! -f "$SETUP_OPENSSL_CNF" ]; then
    echo "CA openssl config file does not exist. Copying..."
    cp "$SRC_OPENSSL_CNF" "$SETUP_PATH"
    echo "Copied CA openssl config file"
  else
    echo "CA openssl config file exists"
  fi

  # Update CA openssl.cnf
  local REPL_CA_OPENSSL_CNF=$(awk -v repl="$SETUP_PATH" '{gsub(/\$ABSOLUTE_PATH/,repl); print }' "$SETUP_OPENSSL_CNF")
  echo "$REPL_CA_OPENSSL_CNF" > "$SETUP_OPENSSL_CNF"

  # Verify or setup CA subdirs

  # private dir
  if [ ! -d "$SETUP_PRIV_DIR" ]; then
    echo "CA priv directory does not exist. Creating..."
    mkdir "$SETUP_PRIV_DIR"
    echo "Created CA priv directory"
  else
    echo "CA priv directory exists"
  fi

  chmod 700 $SETUP_PRIV_DIR

  # certs dir
  if [ ! -d "$SETUP_CERTS_DIR" ]; then
    echo "CA certs directory does not exist. Creating..."
    mkdir "$SETUP_CERTS_DIR"
    echo "Created CA certs directory"
  else
    echo "CA certs directory exists"
  fi

  # newcerts dir
  if [ ! -d "$SETUP_NEWCERTS_DIR" ]; then
    echo "CA newcerts directory does not exist. Creating..."
    mkdir "$SETUP_NEWCERTS_DIR"
    echo "Created CA newcerts directory"
  else
    echo "CA newcerts directory exists"
  fi

  # crl dir
  if [ ! -d "$SETUP_CRL_DIR" ]; then
    echo "CA crl directory does not exist. Creating..."
    mkdir "$SETUP_CRL_DIR"
    echo "Created CA crl directory"
  else
    echo "CA crl directory exists"
  fi

  # csr dir
  if [ ! -d "$SETUP_CSR_DIR" ]; then
    echo "CA csr directory does not exist. Creating..."
    mkdir "$SETUP_CSR_DIR"
    echo "Created CA csr directory"
  else
    echo "CA csr directory exists"
  fi

  if [ ! -f "$SETUP_PATH/index.txt" ]; then
    touch "$SETUP_PATH/index.txt"
  fi

  if [ ! -f "$SETUP_PATH/serial" ]; then
    echo 1000 > "$SETUP_PATH/serial"
  fi
}

gen_ca_cert () {
  local SRC_OPENSSL_CNF=$1
  local SETUP_PATH=$2
  local SETUP_CERT_OPTS=$3

  local SETUP_OPENSSL_CNF="$SETUP_PATH/openssl.cnf"
  local SETUP_PRIV_DIR="$SETUP_PATH/private"
  local SETUP_CERTS_DIR="$SETUP_PATH/certs"
  local SETUP_NEWCERTS_DIR="$SETUP_PATH/newcerts"
  local SETUP_CRL_DIR="$SETUP_PATH/crl"
  local SETUP_CSR_DIR="$SETUP_PATH/csr"

  local SETUP_CERT_PEM_PATH="$SETUP_CERTS_DIR/ca.cert.pem"
  local SETUP_CERT_PKEY_PATH="$SETUP_PRIV_DIR/ca.key.pem"

  setup_ca_paths $SRC_OPENSSL_CNF $SETUP_PATH

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
          $SETUP_CERT_OPTS \
          -out $SETUP_CERT_PEM_PATH

    chmod 444 $SETUP_CERT_PEM_PATH

    echo "Created CA certificate"
  else
    echo "CA certificate already exists"
  fi
}

gen_intermediate_cert() {
  local SRC_OPENSSL_CNF=$1
  local SETUP_CA_PATH=$2
  local SETUP_PATH=$3
  local SETUP_CERT_OPTS=$4

  local SETUP_CA_OPENSSL_CNF="$SETUP_CA_PATH/openssl.cnf"
  local SETUP_OPENSSL_CNF="$SETUP_PATH/openssl.cnf"
  local SETUP_PRIV_DIR="$SETUP_PATH/private"
  local SETUP_CERTS_DIR="$SETUP_PATH/certs"
  local SETUP_NEWCERTS_DIR="$SETUP_PATH/newcerts"
  local SETUP_CRL_DIR="$SETUP_PATH/crl"
  local SETUP_CSR_DIR="$SETUP_PATH/csr"

  local SETUP_CERT_PEM_PATH="$SETUP_CERTS_DIR/intermediate.cert.pem"
  local SETUP_CERT_PKEY_PATH="$SETUP_PRIV_DIR/intermediate.key.pem"
  local SETUP_CERT_CSR_PATH="$SETUP_CSR_DIR/intermediate.csr.pem"

  setup_ca_paths $SRC_OPENSSL_CNF $SETUP_PATH

  # Generate private key
  if [ ! -f "$SETUP_CERT_PKEY_PATH" ]; then
    echo "Generating Intermediate CA private key"
    openssl genrsa -out $SETUP_CERT_PKEY_PATH 4096

    chmod 400 $SETUP_CERT_PKEY_PATH
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
          $SETUP_CERT_OPTS \
          -in $SETUP_CERT_CSR_PATH \
          -out $SETUP_CERT_PEM_PATH

    chmod 444 $SETUP_CERT_PEM_PATH

    echo "Generated Intermediate CA certificate"
  else
    echo "Intermediate CA certificate already exists"
  fi

}

gen_chain_cert () {
  local SETUP_CA_PATH=$1
  local SETUP_INTERMEDIATE_PATH=$2
  local SETUP_CHAIN_CERT_PEM_PATH=$3

  # Create the intermediate chain
  if [ -f "$SETUP_CA_PATH" ]; then
    if [ -f "$SETUP_INTERMEDIATE_PATH" ]; then
      echo "Generating chain certificate"

      if [ -f "$SETUP_CHAIN_CERT_PEM_PATH" ]; then
        chmod 644 $SETUP_CHAIN_CERT_PEM_PATH
      fi
      
      cat $SETUP_INTERMEDIATE_PATH $SETUP_CA_PATH > $SETUP_CHAIN_CERT_PEM_PATH
      chmod 444 $SETUP_CHAIN_CERT_PEM_PATH
      echo "Generated chain certificate $SETUP_CHAIN_CERT_PEM_PATH"
    else
      echo "Missing Intermediate certificate"
    fi
  else
    echo "Missing CA certificate"
  fi
}


# Verify or setup CA directory
gen_ca_cert ./ca/openssl.cnf $CA_DIR "-days $CA_DAYS"
gen_intermediate_cert ./ca/intermediate/openssl.cnf $CA_DIR $INTERMEDIATE_DIR "-days $CA_DAYS"
gen_chain_cert "$CA_DIR/certs/ca.cert.pem" "$INTERMEDIATE_DIR/certs/intermediate.cert.pem" "$INTERMEDIATE_DIR/certs/chain.cert.pem"

