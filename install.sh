#!/bin/bash

# Determine the Apache Cassandra version to download
SERVER_PACKAGE_BASE_URL=https://dist.apache.org/repos/dist/release/cassandra/
LATEST_SERVER_VERSION=$(curl -sS ${SERVER_PACKAGE_BASE_URL} | \
                        grep -Po "href=[\"']\K[^'\"]+" | \
                        grep -P '\d+.\d+' | \
                        sed -e 's/\///' | \
                        grep ${SERVER_VERSION})
[ -z "${LATEST_SERVER_VERSION}" ] && echo "Could not determine latest server version" && exit
SERVER_FILENAME=apache-cassandra-${LATEST_SERVER_VERSION}-bin.tar.gz
SERVER_PACKAGE_URL=${SERVER_PACKAGE_BASE_URL}/${LATEST_SERVER_VERSION}/${SERVER_FILENAME}
CCM_VERSION_TOKENS=($(echo ${LATEST_SERVER_VERSION} | \
                      grep -Po '(\d+\.)+\d+' | \
                      sed -e "s/\\./ /g"))
if [ ${#CCM_VERSION_TOKENS[@]} = 1 ]; then
  export CCM_VERSION=${CCM_VERSION_TOKENS[0]}.0.0
elif [ ${#CCM_VERSION_TOKENS[@]} = 2 ]; then
  export CCM_VERSION=${CCM_VERSION_TOKENS[0]}.${CCM_VERSION_TOKENS[1]}.0
else
  export CCM_VERSION=${CCM_VERSION_TOKENS[0]}.${CCM_VERSION_TOKENS[1]}.${CCM_VERSION_TOKENS[2]}
fi

echo "Smoke tests for Apache Cassandra ${LATEST_SERVER_VERSION} using ${DRIVER_REPO}"
echo "Using ${SERVER_PACKAGE_URL}"

# Install driver specific packages
sudo apt-get update
if [ "${DRIVER_REPO}" = 'cpp-driver' ]; then
  sudo apt-get install -y debhelper libkrb5-dev libssl-dev libuv1-dev zlib1g-dev
fi

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
wget ${SERVER_PACKAGE_URL} -O ${SERVER_FILENAME}
tar xzf ${SERVER_FILENAME} -C ${INSTALL_DIR} --strip-components=1 || exit

# Add 0.version.txt file for CCM
echo "${CCM_VERSION}" > "${INSTALL_DIR}/0.version.txt"

# Verify that ccm cluster creation succeeds
ccm create test -v ${CCM_VERSION}
ccm remove test

# Clone the driver repository
git clone https://github.com/datastax/${DRIVER_REPO}
cd ${DRIVER_REPO} || exit
git fetch --tags
export DRIVER_LATEST_TAG=$(git describe --tags `git rev-list --tags --max-count=1`)
echo ${DRIVER_LATEST_TAG}
