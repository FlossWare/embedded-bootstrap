#!/bin/sh

#export SCRIPT_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

export SCRIPT_HOME=/mnt/md0/alt-f/etc/init.d

. ${SCRIPT_HOME}/util.sh

startMount() {
	log "Start mount"
	
	#mkdir -p /mnt/usbc
	#mount /dev/sdc1 /mnt/usbc
	
	#mkdir -p /mnt/usbd
	#mount /dev/sdd1 /mnt/usbd
	
	#mkdir -p /mnt/usbe
	#mount /dev/sde1 /mnt/usbd
	
	#mkdir -p /mnt/sdc1
	#mount /dev/sdc1 /mnt/sdc1
	
	#mkdir -p /mnt/md0/debian/mnt/usb
	#mount /dev/sdc1 /mnt/md0/debian/mnt/usb
	#mount --bind /mnt/sdc1 /mnt/md0/debian/mnt/usb
}

startBind() {
	log "Start bind"
	
	#mount -o bind /mnt/md0/alt-f/root /root
	
	touch /etc/motd
	grep -q " /etc/motd " /proc/mounts || mount -o bind /mnt/md0/alt-f/etc/motd /etc/motd
	
	mkdir -p /exports
	grep -q " /exports " /proc/mounts || mount -o bind /mnt/md0/exports /exports
	
	#mkdir -p /mnt/md0/exports/usb
	#mount -o bind /mnt/sdc1 /mnt/md0/exports/usb
}


startDebian() {
	log "Start debian"
	
	/mnt/md0/alt-f/etc/init.d/debian.sh start >> /tmp/debian.log 2>&1
}

start() {
	#log "Waiting for Alt-F to be ready"
	
	#while ! aufs.sh -s >& /dev/null
	#while ! aufs.sh -s
	#do
		#log "    Waiting..."
        	#sleep 5
        #done
	
	startMount
	
	startBind
	
	startDebian
}

stopMount() {	
	log "Start unmounting"
	
	#umount /mnt/usbe
	#umount /mnt/usbd
	#umount /mnt/usbc
	#umount /mnt/md0/exports/usb
}

stopBind() {
	umount /exports || echo "WARNING: /exports still mounted" >> /tmp/flossware.log
	umount /etc/motd || echo "WARNING: /etc/motd still mounted" >> /tmp/flossware.log
}

stopDebian() {
	/mnt/md0/alt-f/etc/init.d/debian.sh stop
}

stop() {
	stopDebian
	
	stopBind
	
	stopMount
}

status() {
	echo "Status..."
}

case "$1" in
	start)
		start
	;;
	stop)
		stop
	;;
	restart)
		stop
		sleep 5
		start
	;;
	status)
		status
	;;
	*)
		echo "Usage: $0 (start|stop|restart|status)"
		exit 1
		;;
esac