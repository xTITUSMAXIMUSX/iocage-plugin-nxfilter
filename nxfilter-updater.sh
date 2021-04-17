#!/bin/sh

# Get current version
CURRENT_VERSION=$(/usr/local/nxfilter/bin/version.sh)

# The latest version of NxFilter:
NXFILTER_VERSION=$1
if [ -z "$NXFILTER_VERSION" ]; then
    echo "Checking nxfilter.org for the latest version"
    NXFILTER_VERSION=$(curl -sL 'https://nxfilter.org/p3/download' -H 'X-Requested-With: XMLHttpRequest' | grep -Eo "(http|https)://pub.nxfilter.org/nxfilter-[a-zA-Z0-9./?=_-]*.zip" | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" 2>/dev/null)
fi
NXFILTER_SOFTWARE_URI="http://pub.nxfilter.org/nxfilter-${NXFILTER_VERSION}.zip"

if [ $(echo ${NXFILTER_VERSION} ${CURRENT_VERSION} | awk '{print ($1 > $2)}') = 1 ]; then

    # Switch to a temp directory for the NxFilter download:
    cd $(mktemp -d -t nxfilter)

    echo -n "Downloading NxFilter..."
    /usr/bin/fetch ${NXFILTER_SOFTWARE_URI}
    echo " ok"

    # Stop the service
    /usr/sbin/service nxfilter stop
    echo " ok"

    # Unpack the archive into the /usr/local directory:
    echo -n "Installing NxFilter in /usr/local/nxfilter..."
    /bin/mkdir -p /usr/local/nxfilter
    /usr/bin/tar zxf nxfilter-${NXFILTER_VERSION}.zip -C /usr/local/nxfilter
    echo " ok"

    # add execute permissions
    chmod +x /usr/local/nxfilter/bin/*.sh

    # Start the service
    /usr/sbin/service nxfilter start
    echo "All done!"
else
    echo "NxFilter is up to date"
fi
