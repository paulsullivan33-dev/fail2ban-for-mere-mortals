#!/bin/bash
# append-failures.sh LOGFILE IP COUNT [USER]
# Appends COUNT sshd-style "Failed password" lines for IP to LOGFILE,
# stamped with the current time, the way a real auth log grows.
log=$1; ip=$2; count=$3; user=${4:-root}
for ((i=0; i<count; i++)); do
  ts=$(date '+%b %e %H:%M:%S')
  pid=$(( 1000 + RANDOM % 3000 ))
  port=$(( 41000 + RANDOM % 20000 ))
  if [ "$user" = "root" ]; then
    echo "$ts labhost sshd[$pid]: Failed password for root from $ip port $port ssh2" >> "$log"
  else
    echo "$ts labhost sshd[$pid]: Failed password for invalid user $user from $ip port $port ssh2" >> "$log"
  fi
  sleep 1
done
