#!/bin/sh

# Based on the script from https://github.com/DontBeAPadavan/chroot-debian
# umount (3 times with different flags) is from Qdebian.qpkd (qnapclub)

# Debian folder
CHROOT_DIR=`readlink -f /mnt/md0/debian`
[ -n "$CHROOT_DIR" ] && [ -d "$CHROOT_DIR/proc" ] || { echo "CHROOT_DIR invalid: $CHROOT_DIR"; exit 1; }

CHROOT_SERVICES_LIST=/mnt/md0/alt-f/etc/chroot-services.list

CHROOT_BIN=/usr/sbin/chroot

MountedDirCount="$(/bin/mount | grep -cF " on $CHROOT_DIR/")"

startBind() {
	for dir in dev dev/pts proc sys; do
		grep -q " $CHROOT_DIR/$dir " /proc/mounts || /bin/mount -o bind /$dir $CHROOT_DIR/$dir
	done
	
	touch $CHROOT_DIR/etc/hosts
#	mount -o bind /mnt/md0/Alt-F/etc/hosts $CHROOT_DIR/etc/hosts
	
#	touch $CHROOT_DIR/etc/resolve.conf
#	mount -o bind /mnt/md0/Alt-F/etc/resolv.conf $CHROOT_DIR/etc/resolve.conf
	
	touch ${CHROOT_DIR}/etc/motd
	grep -q " $CHROOT_DIR/etc/motd " /proc/mounts || mount -o bind /mnt/md0/alt-f/etc/motd $CHROOT_DIR/etc/motd
	
	mkdir -p ${CHROOT_DIR}/exports
	grep -q " $CHROOT_DIR/exports " /proc/mounts || mount -o bind /mnt/md0/exports ${CHROOT_DIR}/exports || echo "WARNING: exports bind failed" >> /tmp/debian.log
	
	mkdir -p ${CHROOT_DIR}/media/usb
	if [ -e /dev/sdc1 ]; then
		grep -q " $CHROOT_DIR/media/usb " /proc/mounts || mount /dev/sdc1 ${CHROOT_DIR}/media/usb || echo "WARNING: /dev/sdc1 mount failed — media/usb is a bare directory" >> /tmp/debian.log
	else
		echo "NOTE: no /dev/sdc1 present, skipping media/usb mount" >> /tmp/debian.log
	fi
	
	#mkdir -p ${CHROOT_DIR}/exports/usbc
	#mount /dev/sdc1 ${CHROOT_DIR}/exports/usbc
	
	#mkdir -p ${CHROOT_DIR}/exports/usbd
	#mount /dev/sdd1 ${CHROOT_DIR}/exports/usbd
	
	#mkdir -p ${CHROOT_DIR}/exports/usbe
	#mount /dev/sde1 ${CHROOT_DIR}/exports/usbe
	
	#mkdir -p ${CHROOT_DIR}/mnt/usb
	#mount /mnt/sdc1 ${CHROOT_DIR}/mnt/usb
	
	mkdir -p ${CHROOT_DIR}/root
	grep -q " $CHROOT_DIR/root " /proc/mounts || mount -o bind /mnt/md0/alt-f/root ${CHROOT_DIR}/root
}

startServices() {
	if [ ! -e "$CHROOT_SERVICES_LIST" ]; then
		echo 'WARNING: No Debian services defined.'
		echo "Please, define Debian services to start in $CHROOT_SERVICES_LIST file!"
		echo 'One service per line. Hint: these are script names from Debian /etc/init.d/'
	else
		grep -vE "^[[:space:]]*(#|$)" $CHROOT_SERVICES_LIST | while read -r item; do
			PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
			LC_ALL=C \
			LANGUAGE=C \
			LANG=C \
			$CHROOT_BIN $CHROOT_DIR "/etc/init.d/$item" start </dev/null
			done
	fi
}

start() {
	echo 'Starting Debian services...'
	
	startBind
	
	startServices
}

stopBind() {
	umount ${CHROOT_DIR}/root || echo "WARNING: root still mounted" >> /tmp/debian.log
	if grep -q " ${CHROOT_DIR}/media/usb " /proc/mounts; then
		umount ${CHROOT_DIR}/media/usb || echo "WARNING: media/usb still mounted" >> /tmp/debian.log
	fi
	umount ${CHROOT_DIR}/exports || echo "WARNING: exports still mounted" >> /tmp/debian.log
	umount ${CHROOT_DIR}/etc/motd || echo "WARNING: motd still mounted" >> /tmp/debian.log
	for dir in sys proc dev/pts dev; do
		/bin/umount -l $CHROOT_DIR/$dir 2>/dev/null || echo "WARNING: $dir still mounted" >> /tmp/debian.log
	done
}

stopServices() {
	if [ -e "$CHROOT_SERVICES_LIST" ]; then
		echo 'Stopping Debian services...'
		grep -vE "^[[:space:]]*(#|$)" $CHROOT_SERVICES_LIST | while read -r item; do
			PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
			LC_ALL=C \
			LANGUAGE=C \
			LANG=C \
			$CHROOT_BIN $CHROOT_DIR "/etc/init.d/$item" stop </dev/null
		done
	fi
}

stop() {
	echo 'Stopping Debian services...'
	
	stopServices
	
	stopBind
}

status() {
	if [ $MountedDirCount -gt 0 ]; then
		echo 'Debian services are running'
	else
		echo 'Debian services are stopped'
	fi
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
