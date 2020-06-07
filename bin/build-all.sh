#!/bin/bash

set -e

source bin/version.sh

COUNTRIES="US EU433 EU865 CN JP"
#COUNTRIES=US
#COUNTRIES=CN

BOARDS="ttgo-lora32-v2 ttgo-lora32-v1 tbeam heltec"
#BOARDS=tbeam

OUTDIR=release/latest

# We keep all old builds (and their map files in the archive dir)
ARCHIVEDIR=release/archive 

rm -f $OUTDIR/firmware*

mkdir -p $OUTDIR/bins $OUTDIR/elfs
rm -f $OUTDIR/bins/*

# build the named environment and copy the bins to the release directory
function do_build {
    ENV_NAME=$1
    echo "Building for $ENV_NAME with $PLATFORMIO_BUILD_FLAGS"
    SRCBIN=.pio/build/$ENV_NAME/firmware.bin
    SRCELF=.pio/build/$ENV_NAME/firmware.elf
    rm -f $SRCBIN 

    # The shell vars the build tool expects to find
    export HW_VERSION="1.0-$COUNTRY"
    export APP_VERSION=$VERSION
    export COUNTRY

    pio run --jobs 4 --environment $ENV_NAME # -v
    cp $SRCBIN $OUTDIR/bins/firmware-$ENV_NAME-$COUNTRY-$VERSION.bin
    cp $SRCELF $OUTDIR/elfs/firmware-$ENV_NAME-$COUNTRY-$VERSION.elf
}

# Make sure our submodules are current
git submodule update 

# Important to pull latest version of libs into all device flavors, otherwise some devices might be stale
platformio lib update 

for COUNTRY in $COUNTRIES; do 
    for BOARD in $BOARDS; do
        do_build $BOARD
    done
done

# keep the bins in archive also
cp $OUTDIR/bins/firmware* $OUTDIR/elfs/firmware* $ARCHIVEDIR

cat >$OUTDIR/curfirmwareversion.xml <<XML
<?xml version="1.0" encoding="utf-8"?>

<!-- This file is kept in source control because it reflects the last stable
release.  It is used by the android app for forcing software updates.  Do not edit.
Generated by bin/buildall.sh -->

<resources>
    <string name="cur_firmware_version">$VERSION</string>
</resources>
XML

rm -f $ARCHIVEDIR/firmware-$VERSION.zip
zip --junk-paths $ARCHIVEDIR/firmware-$VERSION.zip $OUTDIR/bins/firmware-*-$VERSION.* images/system-info.bin bin/device-install.sh bin/device-update.sh

echo BUILT ALL
