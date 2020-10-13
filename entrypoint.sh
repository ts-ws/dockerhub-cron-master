#!/bin/bash
SCRIPT_VERSION="v2020.05.18.0002"
echo "[DEBUG] start entrypoint.sh [$SCRIPT_VERSION]"
echo "[DEBUG] `date`"
i=0

while [ $i -lt 2 ]; do
  #echo "[DEBUG] `date`" #debug print
  #echo "[DEBUG] \$i: $i"  #debug print
  if [ $i == 0 ]; then
    echo "[DEBUG] \$i: $i true" #debug print
    i=$((i+1))
    echo "[DEBUG] delete old pid files..."
    rm -vf /tmp/*
    rm -vf /run/rsyslogd.pid
    rm -vf /run/crond.pid
    rm -vf /run/crond.reboot
    rm -vf /var/run/sshd.pid
    rm -vf /var/spool/postfix/pid/master.pid

    echo "[DEBUG] Ensure needed files exist..."
    gzip -v -f -9 < /var/log/syslog > /var/log/syslog.`date +"%Y.%m.%d_%H:%M:%S"`.gz
    rm -vf /var/log/syslog
    gzip -v -f -9 < /var/log/syslog.1 > /var/log/syslog.1.`date +"%Y.%m.%d_%H:%M:%S"`.gz
    rm -vf /var/log/syslog.1
    touch /var/log/syslog
    touch /etc/default/locale
    cp -v /etc/resolv.conf /var/spool/postfix/etc/resolv.conf
    postmap hash:/etc/postfix/sasl_password
    postmap /etc/postfix/sender_canonical

    echo "[DEBUG] correct file rights..."
    chown root /var/log/
    chgrp syslog /var/log/
    chmod 775 /var/log/
    chown syslog /var/log/kern.log
    chgrp adm /var/log/kern.log
    chmod 640 /var/log/kern.log
    chown syslog /var/log/mail.log
    chgrp syslog /var/log/mail.log
    chmod 640 /var/log/mail.log
    chown syslog /var/log/syslog
    chgrp adm /var/log/syslog
    chmod 640 /var/log/syslog
    chown syslog /var/log/auth.log
    chgrp adm /var/log/auth.log
    chmod 640 /var/log/auth.log

    echo "[DEBUG] startup services..."

    echo "[DEBUG] start [/usr/sbin/rsyslogd -n]..."
    /usr/sbin/rsyslogd -n &
    sleep 3

    echo "[DEBUG] start [/usr/sbin/cron -f -l -L 15]..."
    /usr/sbin/cron -f -l -L 15 &
    echo "[DEBUG] start [/usr/sbin/sshd -D -f /etc/ssh/sshd_config]..."
    /usr/sbin/sshd -D -f /etc/ssh/sshd_config &
    echo "[DEBUG] start [/usr/sbin/postfix start-fg]..."
    /usr/sbin/postfix start-fg &
    echo '[DEBUG] start eval "$(ssh-agent -s)"...'
    eval "$(ssh-agent -s)" &
    sleep 3

    rsyslogd_pid=`cat /run/rsyslogd.pid`
    echo "[DEBUG] rsyslogd_pid: $rsyslogd_pid"
    cron_pid=`cat /run/crond.pid`
    echo "[DEBUG] cron_pid: $cron_pid"
    sshd_pid=`cat /var/run/sshd.pid`
    echo "[DEBUG] sshd_pid: $sshd_pid"
    postfix_pid=`cat /var/spool/postfix/pid/master.pid | sed -e 's/\s//g'`
    echo "[DEBUG] postfix_pid: $postfix_pid"
    sleep 3
  else
    #echo "[DEBUG] \$i: $i false"  #debug print

    #echo "[DEBUG] check if rsyslogd[$rsyslogd_pid] is running..." #debug print
    rsyslogd_pid_result=`ps -q $rsyslogd_pid | grep rsyslogd | wc -l`
    if [ $rsyslogd_pid_result != 1 ]; then
      echo "[ERROR] rsyslogd_pid_result: $rsyslogd_pid_result"
      echo "[ERROR] rsyslogd not found shutdown docker!"
      exit 2
    fi

    #echo "[DEBUG] check if crond[$cron_pid] is running..." #debug print
    cron_pid_result=`ps -q $cron_pid | grep cron | wc -l`
    if [ $cron_pid_result != 1 ]; then
      echo "[ERROR] cron_pid_result: $cron_pid_result"
      echo "[ERROR] crond not found shutdown docker!"
      exit 2
    fi

    #echo "[DEBUG] check if sshd[$sshd_pid] is running..." #debug print
    sshd_pid_result=`ps -q $sshd_pid | grep sshd | wc -l`
    if [ $sshd_pid_result != 1 ]; then
      echo "[ERROR] sshd_pid_result: $sshd_pid_result"
      echo "[ERROR] sshd not found shutdown docker!"
      exit 2
    fi

    #echo "[DEBUG] check if postfix[$postfix_pid] is running..." #debug print
    postfix_pid_result=`ps -q $postfix_pid | grep master | wc -l`
    if [ $postfix_pid_result != 1 ]; then
      echo "[ERROR] postfix_pid_result: $postfix_pid_result"
      echo "[ERROR] postfix not found shutdown docker!"
      exit 2
    fi
  fi
  sleep 1
done
