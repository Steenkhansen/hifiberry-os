#!/bin/bash

FOUND=`aplay -l|grep hifiberry`
VERSION=2
CONFIG=/boot/config.txt
I2CBUS=1

function check_i2c {
	modprobe i2c-dev
        if [ ! -e /dev/i2c-$I2CBUS ]; then
                echo "I2C device file not found, need to modify config.txt"
                echo "dtparam=i2c1=on" >> $CONFIG
                echo "Rebooting in 5 seconds, abort reboot?"
                read -t 5 abort
                if [ "$abort" == "" ]; then
                        sync
                        reboot
                fi
        fi
}

function detect_card {
	# Digi/Digi+
	res=`i2cget -y $I2CBUS 0x3b 1 2>/dev/null`
	if [ "$res" == "0x88" ]; then
		echo "digi"
	fi

	# DAC Plus
	res=`i2cget -y $I2CBUS 0x4d 40 2>/dev/null`
	if [ "$res" == "0x02" ]; then
                echo "dacplus"
        fi

	# Amp/Amp+
	res=`i2cget -y $I2CBUS 0x1b 0 2>/dev/null`
        if [ "$res" == "0x6c" ]; then
                echo "amp"
        fi

}

if [ "$FOUND" == "" ]; then
 echo "No HiFiBerry card configured, try to probe using I2C"

 echo "Detecting using I2C" 
 check_i2c
 card=$(detect_card)

 if [ "$card" != "" ]; then
 	echo "Detected $card"

	echo "Creating new config.txt"
	cat $CONFIG | grep -v "hifiberry" > /tmp/config.txt 
	echo "dtoverlay=hifiberry-$card" >> /tmp/config.txt
	mv /tmp/config.txt $CONFIG
	echo "Rebooting in 5 seconds, abort reboot?"
	read -t 5 abort
	if [ "$abort" == "" ]; then
		sync
		reboot
	fi
 else
	echo "Could not find an I2C enabled sound card"
 fi
else
	echo "Found HiFiBerry card: $FOUND"
fi