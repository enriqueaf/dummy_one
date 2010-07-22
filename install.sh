#!/bin/bash

if [ -z "${ONE_LOCATION}" ]; then
    echo "ONE_LOCATION is not defined. Don't know where to copy, aborting."
    exit -1
fi

echo -n "Installing Dummy drivers."

cp one_dummy.conf $ONE_LOCATION/etc/
cp vmm/one_vmm_dummy $ONE_LOCATION/lib/mads
cp vmm/one_vmm_dummy.rb $ONE_LOCATION/lib/mads
chmod +x $ONE_LOCATION/lib/mads/one_vmm_dummy

echo -n "."

cp im/one_im_dummy $ONE_LOCATION/lib/mads
cp im/one_im_dummy.rb $ONE_LOCATION/lib/mads
chmod +x $ONE_LOCATION/lib/mads/one_im_dummy

echo -n "."

mkdir -p $ONE_LOCATION/etc/tm_dummy

cp tm/tm_dummy.conf $ONE_LOCATION/etc/tm_dummy.conf
cp tm/tm_dummyrc $ONE_LOCATION/etc/tm_dummyrc

echo -n "."

mv $ONE_LOCATION/etc/oned.conf $ONE_LOCATION/etc/oned.conf.bck
cp oned.conf $ONE_LOCATION/etc/oned.conf

echo "done"

echo "********************************************************************"
echo "A configuration file ready to use the dummy driver has been installed. You can find a copy of your previous configuration in $ONE_LOCATION/etc/oned.conf "
echo "Add dummy hosts with:"
echo "onehost create <dummy_hostname> im_dummy vmm_dummy tm_dummy"
echo "********************************************************************"

# for i in `seq -w 1 20` ; do echo "onehost create host$i im_dummy vmm_dummy tm_dummy" ; done
