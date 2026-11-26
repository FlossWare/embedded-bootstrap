#!/bin/sh

# Based on the script from https://github.com/DontBeAPadavan/chroot-debian
# umount (3 times with different flags) is from Qdebian.qpkd (qnapclub)

# Debian folder
CHROOT_DIR=`readlink -f /mnt/md0/debian`

CHROOT_SERVICES_LIST=/mnt/md0/alt-f/etc/chroot-services.list

CHROOT_BIN=/usr/sbin/chroot

MountedDirCount="$(/bin/mount | grep $CHROOT_DIR | wc -l)"

startBind() {
	for dir in dev dev/pts proc sys; do
		/bin/mount -o bind /$dir $CHROOT_DIR/$dir
		sleep 2
	done
	
	touch $CHROOT_DIR/etc/hosts
#	mount -o bind /mnt/md0/Alt-F/etc/hosts $CHROOT_DIR/etc/hosts
	
#	touch $CHROOT_DIR/etc/resolve.conf
#	mount -o bind /mnt/md0/Alt-F/etc/resolv.conf $CHROOT_DIR/etc/resolve.conf
	
	touch ${CHROOT_DIR}/etc/motd
	mount -o bind /mnt/md0/alt-f/etc/motd $CHROOT_DIR/etc/motd
	
	mkdir -p ${CHROOT_DIR}/exports
	mount -o bind /mnt/md0/exports ${CHROOT_DIR}/exports
	
	mkdir -p ${CHROOT_DIR}/media/usb
	[ -e /dev/sdc1 ] && mount /dev/sdc1 ${CHROOT_DIR}/media/usb
	
	#mkdir -p ${CHROOT_DIR}/exports/usbc
	#mount /dev/sdc1 ${CHROOT_DIR}/exports/usbc
	
	#mkdir -p ${CHROOT_DIR}/exports/usbd
	#mount /dev/sdd1 ${CHROOT_DIR}/exports/usbd
	
	#mkdir -p ${CHROOT_DIR}/exports/usbe
	#mount /dev/sde1 ${CHROOT_DIR}/exports/usbe
	
	#mkdir -p ${CHROOT_DIR}/mnt/usb
	#mount /mnt/sdc1 ${CHROOT_DIR}/mnt/usb
	
	mkdir -p ${CHROOT_DIR}/root
	mount /mnt/md0/alt-f/root ${CHROOT_DIR}/root
}

startServices() {
	if [ ! -e "$CHROOT_SERVICES_LIST" ]; then
		echo 'WARNING: No Debian services defined.'
		echo "Please, define Debian services to start in $CHROOT_SERVICES_LIST file!"
		echo 'One service per line. Hint: these are script names from Debian /etc/init.d/'
	else
		for item in $(cat $CHROOT_SERVICES_LIST); do
			PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
			LC_ALL=C \
			LANGUAGE=C \
			LANG=C \
			$CHROOT_BIN $CHROOT_DIR /etc/init.d/$item start
			done
	fi
}

start() {
	echo 'Starting Debian services...'
	
	startBind
	
	startServices
}

stopBind() {
	umount ${CHROOT_DIR}/root
	
	#umount ${CHROOT_DIR}/exports/usbd
	#umount ${CHROOT_DIR}/exports/usbc
	#umount ${CHROOT_DIR}/exports
	#umount $CHROOT_DIR/etc/motd
	
#	umount $CHROOT_DIR/etc/resolve.conf
	umount $CHROOT_DIR/etc/hosts
	
	for dir in dev dev/pts proc sys; do
		/bin/umount -l $CHROOT_DIR/$dir
		sleep 2
	done
}

stopServices() {
	if [ -e "$CHROOT_SERVICES_LIST" ]; then
		echo 'Stopping Debian services...'
		for item in $(cat $CHROOT_SERVICES_LIST); do
			PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
			LC_ALL=C \
			LANGUAGE=C \
			LANG=C \
			$CHROOT_BIN $CHROOT_DIR /etc/init.d/$item stop
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
