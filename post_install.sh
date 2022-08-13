#!/bin/sh

# Installs NxFilter DNS filter software on TrueNAS jail.


clear

# The latest version of NxFilter:
NXFILTER_VERSION=$1
if [ -z "$NXFILTER_VERSION" ]; then
  echo "Checking nxfilter.org for the latest version"
  NXFILTER_VERSION=$(
    curl -sL 'https://nxfilter.org/p3/download' -H 'X-Requested-With: XMLHttpRequest' | grep -Eo "(http|https)://pub.nxfilter.org/nxfilter-[a-zA-Z0-9./?=_-]*.zip" | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" 2>/dev/null
  )
fi
NXFILTER_SOFTWARE_URI="https://pub.nxfilter.org/nxfilter-${NXFILTER_VERSION}.zip"

# service script
SERVICE_SCRIPT_URI="https://raw.githubusercontent.com/xTITUSMAXIMUSX/iocage-plugin-nxfilter/master/nxfilter.sh"


# Stop NxFilter if it's already running
if [ -f /usr/local/etc/rc.d/nxfilter ]; then
  echo -n "Stopping the NxFilter service..."
  /usr/sbin/service nxfilter stop
  echo " ok"
fi

# Make sure nxd.jar isn't still running for some reason
if [ ! -z "$(ps ax | grep "/usr/local/nxfilter/nxd.jar" | grep -v grep | awk '{ print $1 }')" ]; then
  echo -n "Killing nxd.jar process..."
  /bin/kill -15 `ps ax | grep "/usr/local/nxfilter/nxd.jar" | grep -v grep | awk '{ print $1 }'`
  echo " ok"
fi

# Switch to a temp directory for the NxFilter download:
cd `mktemp -d -t nxfilter`

echo -n "Downloading NxFilter..."
/usr/bin/fetch ${NXFILTER_SOFTWARE_URI}
echo " ok"

# Unpack the archive into the /usr/local directory:
echo -n "Installing NxFilter in /usr/local/nxfilter..."
/bin/mkdir -p /usr/local/nxfilter
/usr/bin/tar zxf nxfilter-${NXFILTER_VERSION}.zip -C /usr/local/nxfilter
echo " ok"


# Fetch the service script from github:
echo -n "Downloading service script..."
/usr/bin/fetch -o /etc/rc.d/nxfilter ${SERVICE_SCRIPT_URI}
echo " ok"

# add execute permissions
chmod +x /etc/rc.d/nxfilter
chmod +x /usr/local/nxfilter/bin/*.sh

#Enable service of not already
if [ ! -f /etc/rc.conf ] || [ $(grep -c nxfilter_enable /etc/rc.conf) -eq 0 ]; then
  echo -n "Enabling the NxFilter service..."
  sysrc nxfilter_enable=YES
  echo " ok"
fi

echo -n "Starting the NxFilter service..."
/usr/sbin/service nxfilter start
echo "All done!"
