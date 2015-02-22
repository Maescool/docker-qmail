#!/bin/bash

set -e

QMAIL_HOME="/var/qmail"
QMAIL_LOG_DIR="/var/log/qmail"
VPOPMAIL_HOME="/home/vpopmail"

QMAIL_DOWNLOAD="http://www.qmail.org/netqmail-1.06.tar.gz"
VPOPMAIL_DOWNLOAD="http://downloads.sourceforge.net/project/vpopmail/vpopmail-stable/5.4.33/vpopmail-5.4.33.tar.gz"
AUTORESPOND_DOWNLOAD="http://qmail.ixip.net/download/autorespond-2.0.5.tar.gz"
QMAILADMIN_DOWNLOAD="http://downloads.sourceforge.net/project/qmailadmin/qmailadmin-devel/qmailadmin-1.2.16.tar.gz"
MAILDROP_DOWNLOAD="http://downloads.sourceforge.net/project/courier/maildrop/2.8.1/maildrop-2.8.1.tar.bz2"

## QMAIL INSTALL BASED ON LWQ ##
cd /usr/src
wget $QMAIL_DOWNLOAD -O netqmail-1.06.tar.gz

tar -zxf netqmail-1.06.tar.gz
cd netqmail-1.06

groupadd -g 161 nofiles
useradd -u 161 -g nofiles -d ${QMAIL_HOME}/alias alias
useradd -u 162 -g nofiles -d ${QMAIL_HOME} qmaild
useradd -u 163 -g nofiles -d ${QMAIL_HOME} qmaill
useradd -u 164 -g nofiles -d ${QMAIL_HOME} qmailp
groupadd -g 162 qmail
useradd -u 165 -g qmail -d ${QMAIL_HOME} qmailq
useradd -u 166 -g qmail -d ${QMAIL_HOME} qmailr
useradd -u 167 -g qmail -d ${QMAIL_HOME} qmails

make setup check

mkdir -p ${QMAIL_HOME}/supervise/qmail-send
mkdir -p ${QMAIL_HOME}/supervise/qmail-smtpd

cat > ${QMAIL_HOME}/supervise/qmail-send/run <<EOF
#!/bin/sh
exec ${QMAIL_HOME}/rc
EOF
chmod 755 ${QMAIL_HOME}/supervise/qmail-send/run

cat > ${QMAIL_HOME}/rc <<EOF
#!/bin/sh

# Using stdout for logging
# Using control/defaultdelivery from qmail-local to deliver messages by default

exec env - PATH="${QMAIL_HOME}/bin:\$PATH" \
qmail-start "\`cat ${QMAIL_HOME}/control/defaultdelivery\`"
EOF
chmod 755 ${QMAIL_HOME}/rc

cat > ${QMAIL_HOME}/supervise/qmail-smtpd/run <<EOF
#!/bin/sh

QMAILDUID=\`id -u qmaild\`
NOFILESGID=\`id -g qmaild\`
MAXSMTPD=\`cat ${QMAIL_HOME}/control/concurrencyincoming\`
LOCAL=\`head -1 ${QMAIL_HOME}/control/me\`

if [ -z "\$QMAILDUID" -o -z "\$NOFILESGID" -o -z "\$MAXSMTPD" -o -z "\$LOCAL" ]; then
    echo QMAILDUID, NOFILESGID, MAXSMTPD, or LOCAL is unset in
    echo ${QMAIL_HOME}/supervise/qmail-smtpd/run
    exit 1
fi

if [ ! -f ${QMAIL_HOME}/control/rcpthosts ]; then
    echo "No ${QMAIL_HOME}/control/rcpthosts!"
    echo "Refusing to start SMTP listener because it'll create an open relay"
    exit 1
fi
exec /usr/bin/tcpserver -v -R -l "\$LOCAL" -x /etc/tcp.smtp.cdb -c "\$MAXSMTPD" \
        -u "\$QMAILDUID" -g "\$NOFILESGID" 0 smtp ${QMAIL_HOME}/bin/qmail-smtpd 2>&1
EOF
chmod 755 ${QMAIL_HOME}/supervise/qmail-smtpd/run

# configure supervisord to start qmail
cat > /etc/supervisor/conf.d/qmail-send.conf <<EOF
[program:qmail-send]
directory=${QMAIL_HOME}
environment=HOME=${QMAIL_HOME}
command=${QMAIL_HOME}/supervise/qmail-send/run
user=root
autostart=true
autorestart=true
stdout_logfile=${QMAIL_LOG_DIR}/%(program_name)s.log
stderr_logfile=${QMAIL_LOG_DIR}/%(program_name)s.log
EOF

cat > /etc/supervisor/conf.d/qmail-smtpd.conf <<EOF
[program:qmail-smtpd]
directory=${QMAIL_HOME}
environment=HOME=${QMAIL_HOME}
command=${QMAIL_HOME}/supervise/qmail-smtpd/run
user=root
autostart=true
autorestart=true
stdout_logfile=${QMAIL_LOG_DIR}/%(program_name)s.log
stderr_logfile=${QMAIL_LOG_DIR}/%(program_name)s.log
EOF

cat > /etc/tcp.smtp <<EOF
127.:allow,RELAYCLIENT=""
172.17.:allow,RELAYCLIENT=""
EOF
tcprules /etc/tcp.smtp.cdb /etc/tcp.smtp.tmp < /etc/tcp.smtp
chmod 644 /etc/tcp.smtp.cdb

mkdir ${QMAIL_LOG_DIR}

## VPOPMAIL INSTALL ##
cd /usr/src

wget $VPOPMAIL_DOWNLOAD -O vpopmail-5.4.33.tar.gz
tar -zxf vpopmail-5.4.33.tar.gz
cd vpopmail-5.4.33

groupadd -g 89 vchkpw
useradd -u 89 -g vchkpw vpopmail

./configure
make install-strip

#Legacy support:
ln -s /home/vpopmail /var/lib/vpopmail


## EZMLM
cd /usr/src
git clone https://github.com/bruceg/ezmlm-idx.git
cd ezmlm-idx
bash tools/makemake
make clean
make; make man
make mysql
make install

## Autoresponder ##
cd /usr/src
wget ${AUTORESPOND_DOWNLOAD} -O autorespond-2.0.5.tar.gz
tar -zxf autorespond-2.0.5.tar.gz
cd autorespond-2.0.5
make && make install

## Qmailadmin ##
cd /usr/src
wget ${QMAILADMIN_DOWNLOAD} -O qmailadmin-1.2.16.tar.gz
tar -zxf qmailadmin-1.2.16.tar.gz
cd qmailadmin-1.2.16

./configure --enable-htmldir=/usr/share/qmailadmin/html --enable-imagedir=/usr/share/qmailadmin/images --enable-cgibindir=/usr/lib/cgi-bin --enable-htmllibdir=/usr/share/qmailadmin --enable-imageurl=/images --enable-cgipath=/qmailadmin
make
make install-strip


# make sure fcgi runs
cat > /etc/supervisor/conf.d/fgci.conf <<EOF
[program:fcgi]
priority=10
directory=/tmp
command=/usr/bin/spawn-fcgi -n -P /var/run/fcgiwrap.pid -F 1 -s /var/run/fcgiwrap.socket -U www-data -G www-data /usr/sbin/fcgiwrap
user=root
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/%(program_name)s.log
stderr_logfile=/var/log/supervisor/%(program_name)s.log
EOF

# configure supervisord to start nginx
cat > /etc/supervisor/conf.d/nginx.conf <<EOF
[program:nginx]
priority=20
directory=/tmp
command=/usr/sbin/nginx -g "daemon off;"
user=root
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/%(program_name)s.log
stderr_logfile=/var/log/supervisor/%(program_name)s.log
EOF

rm -f /etc/nginx/sites-enabled/default
cp /app/setup/config/nginx-qmailadmin.conf /etc/nginx/sites-enabled/qmailadmin.conf


## Dovecot
cd /usr/src
apt-get source dovecot
apt-get -y build-dep dovecot
cd dovecot-*

# Add vpopmail support
sed -i '/--with-sqlite/ s/\\$/ --with-vpopmail \\/' debian/rules
# build dovecot
dpkg-buildpackage -rfakeroot -uc -b

cd ..
# Install dovecot and make sure it doesn't get overwritten
dpkg -i dovecot-core_* dovecot-imapd_* dovecot-lmtpd_* dovecot-managesieved_* dovecot-pop3d_* dovecot-sieve_*
apt-mark hold dovecot-core dovecot-imapd dovecot-lmtpd dovecot-managesieved dovecot-pop3d dovecot-sieve

# Configure supervisord to start dovecot
cat > /etc/supervisor/conf.d/dovecot.conf <<EOF
[program:dovecot]
directory=/tmp
command=/usr/sbin/dovecot -F
user=root
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/%(program_name)s.log
stderr_logfile=/var/log/supervisor/%(program_name)s.log
EOF

cd /etc/dovecot/conf.d/
sed -i 's/!include auth-system.conf.ext/\#!include auth-system.conf.ext/' 10-auth.conf
sed -i 's/\#!include auth-vpopmail.conf.ext/!include auth-vpopmail.conf.ext/' 10-auth.conf
sed -i 's/\#first_valid_uid = .*$/first_valid_uid = 89/' 10-mail.conf
sed -i 's/\#first_valid_gid = .*$/first_valid_gid = 89/' 10-mail.conf
sed -i 's/^mail_location = .*$/mail_location = maildir:~\/Maildir/' 10-mail.conf

cd /etc/dovecot/
sed -i 's/\#login_trusted_networks =/login_trusted_networks = 172.17.0.0/16' dovecot.conf
