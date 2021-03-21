#!/bin/sh

# Installs NxFilter DNS filter software on TrueNAS jail.


clear

#Change pkg to latest
sed -i .conf 's/quarterly/latest/g' /etc/pkg/FreeBSD.conf

#install required packages
pkg  install -y curl openjdk8-jre

# The latest version of NxFilter:
NXFILTER_VERSION=$1
if [ -z "$NXFILTER_VERSION" ]; then
  echo "NxFilter version not supplied, checking nxfilter.org for the latest version..."
  NXFILTER_VERSION=$(
    curl -sL 'https://nxfilter.org/p3/download' -H 'X-Requested-With: XMLHttpRequest' | grep -Eo "(http|https)://pub.nxfilter.org/nxfilter-[a-zA-Z0-9./?=_-]*.zip" | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" 2>/dev/null
  )
fi
NXFILTER_SOFTWARE_URI="http://pub.nxfilter.org/nxfilter-${NXFILTER_VERSION}.zip"

# service script
SERVICE_SCRIPT_URI="https://raw.githubusercontent.com/xTITUSMAXIMUSX/iocage-plugin-nxfilter/master/nxfilter.sh"


# Stop NxFilter if it's already running
if [ -f /usr/local/etc/rc.d/nxfilter.sh ]; then
  echo -n "Stopping the NxFilter service..."
  /usr/sbin/service nxfilter.sh stop
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
/usr/bin/fetch -o /etc/rc.d/nxfilter.sh ${SERVICE_SCRIPT_URI}
echo " ok"

# add execute permissions
chmod +x /etc/rc.d/nxfilter.sh
chmod +x /usr/local/nxfilter/bin/*.sh

# Add the startup variable to rc.conf.local.
# Eventually, this step will need to be folded into pfSense, which manages the main rc.conf.
# In the following comparison, we expect the 'or' operator to short-circuit, to make sure the file exists and avoid grep throwing an error.
if [ ! -f /etc/rc.conf ] || [ $(grep -c nxfilter_enable /etc/rc.conf) -eq 0 ]; then
  echo -n "Enabling the NxFilter service..."
  sysrc nxfilter_enable=YES
  echo " ok"
fi

echo -n "Starting the NxFilter service..."
/usr/sbin/service nxfilter.sh start
echo "All done!"
