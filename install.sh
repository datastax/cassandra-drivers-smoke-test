#!/bin/bash

# Install CCM
git clone --branch master --single-branch https://github.com/riptano/ccm.git
pushd ccm || exit
sudo python setup.py install
popd
ccm status || true

export CCM_PATH="$(pwd)/ccm"

# Download and install Apache Cassandra
export INSTALL_DIR="${HOME}/.ccm/repository/${CCM_VERSION}"
echo ${INSTALL_DIR}
mkdir -p ${INSTALL_DIR}
wget ${SERVER_PACKAGE_URL} -O server.tar.gz
tar xzf server.tar.gz -C ${INSTALL_DIR} --strip-components=1 || exit

# Add 0.version.txt file for ccm
VERSION_TOKENS=($(echo ${CCM_VERSION} | sed -e "s/[\\.|-]/ /g"))
echo "${VERSION_TOKENS[0]}.${VERSION_TOKENS[1]}.${VERSION_TOKENS[2]}" > "${INSTALL_DIR}/0.version.txt"

# Verify that ccm cluster creation succeeds
ccm create test -v ${CCM_VERSION}
ccm remove test

# Clone the driver repository
git clone https://github.com/datastax/${DRIVER_REPO}
cd ${DRIVER_REPO} || exit
git fetch --tags
export DRIVER_LATEST_TAG=$(git describe --tags `git rev-list --tags --max-count=1`)
echo ${DRIVER_LATEST_TAG}
