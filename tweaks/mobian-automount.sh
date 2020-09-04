#!/bin/sh

OPERATION=$1
DEVICE=$2

MOUNTPOINT=/media/sdcard

usage() {
    echo "USAGE: $0 MODE DEVICE"
    echo "MODE:"
    echo "\t-m\tSetup automount for DEVICE"
    echo "\t-u\tUnmount DEVICE"
    exit 1
}

delete_mountpoints() {
    for dir in ${MOUNTPOINT}/part*; do
        rmdir ${dir}
    done
}

mount_sdcard() {
    delete_mountpoints
    if [ "${PARTNUM}" = "1" ]; then
        # Mount on $MOUNTPOINT if we have only one partition
        systemd-mount --no-block -A -G --timeout-idle-sec=1s ${DEVICE}p1 ${MOUNTPOINT}
    else
        for PART in ${PARTLIST}; do
            # SD cards with multiple partitions get mounted on $MOUNTPOINT/partX
            PARTNUM=`echo ${PART} | sed "s%${DEVICE}p%%"`
            systemd-mount --no-block -A -G --timeout-idle-sec=1s ${PART} ${MOUNTPOINT}/part${PARTNUM}
        done
    fi
}

unmount_sdcard() {
    if [ -d ${MOUNTPOINT}/part1 ]; then
        for dir in ${MOUNTPOINT}/*; do
            systemd-mount --unmount ${dir}
        done
    else
        systemd-mount --unmount ${MOUNTPOINT}
    fi
    delete_mountpoints
}

[ "${OPERATION}" = "-m" -o "${OPERATION}" = "-u" ] || usage
[ -b $DEVICE ] || usage

PARTLIST=`sudo fdisk -l ${DEVICE} | grep "^${DEVICE}" | cut -d ' ' -f 1`
PARTNUM=`echo "${PARTLIST}" | wc -w`

# Do not automount the system device
ROOTDEV=`sed -e 's/^.*root=\(\/dev\/mmcblk.\).*$/\1/' /proc/cmdline`
[ "${DEVICE}" = "${ROOTDEV}" ] && exit 0

case ${OPERATION} in
    "-m") mount_sdcard ;;
    "-u") unmount_sdcard ;;
    *)    usage ;;
esac
