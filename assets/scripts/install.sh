#/bin/bash

cp qmail-run /usr/local/bin/
cp vpopmail-script /usr/local/bin/

chmod 750 /usr/local/bin/qmail-run
chmod 750 /usr/local/bin/vpopmail-script

cd /usr/local/bin
ln -s vpopmail-script authvchkpw
ln -s vpopmail-script clearopensmtp
ln -s vpopmail-script dotqmail2valias
ln -s vpopmail-script vaddaliasdomain
ln -s vpopmail-script vadddomain
ln -s vpopmail-script vadduser
ln -s vpopmail-script valias
ln -s vpopmail-script vchangepw
ln -s vpopmail-script vchkpw
ln -s vpopmail-script vconvert
ln -s vpopmail-script vdeldomain
ln -s vpopmail-script vdelivermail
ln -s vpopmail-script vdeloldusers
ln -s vpopmail-script vdeluser
ln -s vpopmail-script vdominfo
ln -s vpopmail-script vipmap
ln -s vpopmail-script vkill
ln -s vpopmail-script vlist
ln -s vpopmail-script vmkpasswd
ln -s vpopmail-script vmoddomlimits
ln -s vpopmail-script vmoduser
ln -s vpopmail-script vpasswd
ln -s vpopmail-script vpopbull
ln -s vpopmail-script vpopmaild
ln -s vpopmail-script vsetuserquota
ln -s vpopmail-script vusagec
ln -s vpopmail-script vuserinfo
