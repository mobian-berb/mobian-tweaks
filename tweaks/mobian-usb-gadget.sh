#!/bin/sh

CONFIGFS=/sys/kernel/config/usb_gadget/g1
USB_VENDORID="0x1D6B"  # Linux Foundation
USB_PRODUCTID="0x0104" # Multifunction composite gadget
USB_MANUF="Mobian Project"
USB_PRODUCT="Mobian"
USB_SERIAL=`cat /etc/machine-id`

setup() {
    # Required to make a composite gadget
    modprobe libcomposite

    # Create all required directories
    mkdir -p $CONFIGFS
    mkdir -p $CONFIGFS/strings/0x409
    mkdir -p $CONFIGFS/configs/c.1
    mkdir -p $CONFIGFS/configs/c.1/strings/0x409

    # Setup IDs and strings
    echo $USB_VENDORID > $CONFIGFS/idVendor
    echo $USB_PRODUCTID > $CONFIGFS/idProduct
    echo $USB_MANUF > $CONFIGFS/strings/0x409/manufacturer
    echo $USB_PRODUCT > $CONFIGFS/strings/0x409/product
    echo $USB_SERIAL > $CONFIGFS/strings/0x409/serialnumber

    # Create ECM (ethernet) function
    mkdir $CONFIGFS/functions/ecm.usb0

    # TODO: create RNDIS function for Windows compatibility

    # Create MTP using FunctionFS
    mkdir $CONFIGFS/functions/ffs.mtp

    # Create configuration
    echo "Ethernet + MTP" > $CONFIGFS/configs/c.1/strings/0x409/configuration
    ln -s $CONFIGFS/functions/ecm.usb0 $CONFIGFS/configs/c.1
    ln -s $CONFIGFS/functions/ffs.mtp $CONFIGFS/configs/c.1

    # Mount the MTP FunctionFS
    mkdir -p /dev/ffs-mtp
    mount -t functionfs mtp /dev/ffs-mtp
}

start() {
    UDC=`ls /sys/class/udc`
    echo "$UDC" > $CONFIGFS/UDC
}

reset() {
    # Remove USB gadget
    rm $CONFIGFS/configs/c.1/ffs.mtp
    rm $CONFIGFS/configs/c.1/ecm.usb0
    rmdir $CONFIGFS/configs/c.1/strings/0x409/
    rmdir $CONFIGFS/configs/c.1/
    rmdir $CONFIGFS/functions/ffs.mtp
    rmdir $CONFIGFS/functions/ecm.usb0
    rmdir $CONFIGFS/strings/0x409/
    rmdir $CONFIGFS

    # Unmount FunctionFS and delete its mount point
    umount /dev/ffs-mtp
    rmdir /dev/ffs-mtp
}


case "$1" in
    reset) reset ;;
    setup) setup ;;
    start) start ;;
    *) ;;
esac
