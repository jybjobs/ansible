#!/bin/bash
#Requirements: etckeeper, diffcolor

#This script concatenates multiple files of haproxy configuration into
#one file, and than checks if monolithic config contains errors. If everything is
#OK with new config script will write new config to $CURRENTCFG and reload haproxy
#Also, script will commit changes to etckeeper, if you don't use etckeeper you
#should start using it.
#Script assumes following directory structure:
#/etc/haproxy/conf.d/
#├── 00-global.cfg
#├── 15-lazic.cfg
#├── 16-togs.cfg
#├── 17-svartberg.cfg
#├── 18-home1.cfg.disabled
#└── 99-globalend.cfg
#Every site has it's own file, so you can disable site by changing
#it's file extension, or appending .disabled, like I do.


CURRENTCFG=/etc/haproxy/haproxy.cfg
NEWCFG=/tmp/haproxy.cfg.tmp
CONFIGDIR=/etc/haproxy/conf.d

echo "Compiling *.cfg files from $CONFIGDIR"
ls $CONFIGDIR/*.cfg
cat $CONFIGDIR/*.cfg > $NEWCFG
echo "Differences between current and new config"
diff -s -U 3 $CURRENTCFG $NEWCFG | colordiff
if [ $? -ne 0 ]; then
        echo "You should make some changes first :)"
        exit 1 #Exit if old and new configuration are the same
fi
echo -e "Checking if new config is valid..."
haproxy -c -f $NEWCFG

if [ $? -eq 0 ]; then
        echo "Working..."
        cat /etc/haproxy/conf.d/*.cfg > $CURRENTCFG
        etckeeper commit -m "Updating haproxy configuration"
        echo "Reloading haproxy..."
        service haproxy restart              
else
        echo "There are errors in new configuration, please fix them and try again."
        exit 1
fi

