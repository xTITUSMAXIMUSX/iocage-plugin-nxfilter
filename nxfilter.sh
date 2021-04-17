#!/bin/sh

# REQUIRE: FILESYSTEMS NETWORKING
# PROVIDE: nxfilter

. /etc/rc.subr

name="nxfilter"
desc="NxFilter DNS filter."
rcvar="nxfilter_enable"
command="/usr/sbin/daemon"
start_cmd="nxfilter_start"
stop_cmd="nxfilter_stop"
status_cmd="nxfilter_status"

pidfile="/var/run/${name}.pid"


nxfilter_start()
{
  if checkyesno ${rcvar}; then
    echo "Starting NxFilter..."
    /usr/local/nxfilter/bin/startup.sh -d &
    echo `ps | grep 'nxd.jar' | grep -v grep | awk '{ print $1 }'` > $pidfile
  fi
}

nxfilter_stop()
{
  if [ -f $pidfile ]; then

    /usr/local/nxfilter/bin/shutdown.sh &
    rm $pidfile
    sleep 1
    echo "Server stopped."

  else
    echo "NxFilter not running. No PID file found."
  fi
}

nxfilter_status()
{
        if [ -e "${pidfile}" ]; then
                echo "${name} is running as pid ${pidfile}"
        else
                echo "${name} is not running"
        fi
}

load_rc_config ${name}
run_rc_command "$1"