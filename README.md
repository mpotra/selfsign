# selfsign
SelfSign - Generate self-signed certificates on Linux

The package contains two scripts

- `selfsign-ca` - used to generate CA and Intermediate CA certificates. These two certificates should be installed in Chrome/Firefox/browser as Authority certificates. They will be used to generate the server certificate by the `selfsign` command.
- `selfsign` - used to generate a server certificate signed by the two CA and Intermediate certificates. It will generate domain and subdomains `*` wildcard for the domain, as `subjectAltName`.

## Usage

After install, you will need to run `selfsign-ca` one time to generate the CA and Intermediate certificates. Install these into your browser.

For every server certificate that you need to generate, use the `selfsign example.com` command where you want to generate the certificate.

`selfsign example.com [opts]`

This will create a `example.com` directory with the following files:
- `chain.pem` - the chain certificate PEM
- `privkey.pem` - the certificate private key
- `cert.pem` - the certificate PEM
- `fullchain.pem` - the fullchain PEM file (chain + cert)
- config files used to generate the above. Removed when using `--clean` or `y` on the clean prompt.

Options:
- `--days <n>` - Set the certificate valid period to `<n>` days. _Default: `1000`_
- `-n=<n>` - Same as `--days <n>`
- `--domain <domain.tld>` - Set the domain the certificate is issued for. Example: `--domain example.com`
- `-d=<domain>` - Same as `--domain <domain.tld>`
- `--path <path>` - Path where to generate the `<domain.tld>` directory. Example `--path /home` will generate certificates in `/home/domain.tld` directory. _Default: current path_
- `-p=<path>` - Same as `--path <path>`
- `--silent` - Do not prompt for clean up at end of execution.
- `-s` - Same as `--silent`
- `--clean` - Clean up the configs from the output directory, after execution. Will not prompt for cleanup at the end.
- `-c` - Same as `--clean`

## Installation

Requires `openssl`

### Install using a RPM package

You may install the provided `.rpm` package in the `builds` directory.
Example: `sudo dnf install buids/selfsign-1.0-1.fc36.noarch.rpm`

You may build a `.rpm` package from the sources, using the included [spec file](https://github.com/mpotra/selfsign/blob/main/selfsign.spec)
Example: `rpmbuild -ba selfsign.spec`

Once the package is built, you may install it via _rpm_ or _dnf_.
Example: `sudo dnf install ~/rpmbuild/RPMS/noarch/selfsign-1.0-1.fc36.noarch.rpm`

### Install manually

Installing manually requires 3 steps.

#### Step 1 - Executables
Copy `selfsign-ca.sh` and `selfsign.sh` into a directory of your choice. Ideally you'd add or have this directory set in the `PATH` env variable.
Example: Place them in `/usr/bin`

**Make sure to set the `SELFSIGN_INSTALL_DIR` variable** inside each script, to the path where you have the configs set.
Optionally, you can leave the scripts and the configs in the same directory. See `Step 2 - Configs` below.

#### Step 2 - Configs
Place the `ca` folder provided in this repository in a directory of your choice. The CA and Intermediate certificates will be generated inside the `<path>/ca/certs` and `<path>/ca/intermediate/certs` directories.

**Make sure to replace `dir = $INSTALL_PATH` in each** `ca/openssl-template.cnf` and `ca/intermediate/openssl-template.cnf` with `dir = <actual path>`
For example, installing configs in `/var/lib/selfsign` requires the following changes:

1. Rename `/var/lib/selfsign/ca/openssl-template.cnf` to `/var/lib/selfsign/ca/openssl.cnf`
2. Replace `$INSTALL_DIR` inside the openssl.cnf file with `/var/lib/selfsign/ca`
3. Rename `/var/lib/selfsign/ca/intermediate/openssl-template.cnf` to `/var/lib/selfsign/ca/intermediate/openssl.cnf`
4. Replace `$INSTALL_DIR` inside the intermediate/openssl.cnf file with `/var/lib/selfsign/ca/intermediate`

**Make sure that you have `SELFSIGN_INSTALL_DIR=/var/lib/selfsign` set up** in your `selfsign-ca.sh` and `selfsign.sh` executables.

#### Step 3 - Create empty directories

Create the following directories:
- `<path>/ca/certs`
- `<path>/ca/private`
- `<path>/ca/newcerts`
- `<path>/ca/csr`
- `<path>/ca/crl`
- `<path>/ca/intermediate/certs`
- `<path>/ca/intermediate/private`
- `<path>/ca/intermediate/newcerts`
- `<path>/ca/intermediate/csr`
- `<path>/ca/intermediate/crl`

## License

See [License](https://github.com/mpotra/selfsign/blob/main/LICENSE)
