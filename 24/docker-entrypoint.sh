#!/bin/bash
set -e

if [ -n "${UID+x}" ] && [ "${UID}" != "0" ]; then
  usermod -u "$UID" bitcoin
fi

if [ -n "${GID+x}" ] && [ "${GID}" != "0" ]; then
  groupmod -g "$GID" bitcoin
fi

echo "$0: assuming uid:gid for bitcoin:bitcoin of $(id -u bitcoin):$(id -g bitcoin)"

if [ $(echo "$1" | cut -c1) = "-" ]; then
  echo "$0: assuming arguments for bitcoind"

  set -- bitcoind "$@"
fi

if [ $(echo "$1" | cut -c1) = "-" ] || [ "$1" = "bitcoind" ]; then
  mkdir -p "$BITCOIN_DATA"
  chmod 700 "$BITCOIN_DATA"
  # Fix permissions for home dir.
  chown -R bitcoin:bitcoin "$(getent passwd bitcoin | cut -d: -f6)"
  # Fix permissions for bitcoin data dir.
  chown -R bitcoin:bitcoin "$BITCOIN_DATA"

  echo "$0: setting data directory to $BITCOIN_DATA"

  set -- "$@" -datadir="$BITCOIN_DATA"

  # Ensure the /home/bitcoin/.bitcoin directory exists.
  mkdir -p /home/bitcoin/.bitcoin
  # New: Ensure the /root/.bitcoin directory exists before copying.
  if [ ! -d "/root/.bitcoin" ]; then
    mkdir -p /root/.bitcoin
    # Only set permissions if the directory had to be created to avoid unnecessary permission changes.
    chown bitcoin:bitcoin /root/.bitcoin
    chmod 700 /root/.bitcoin
  fi

  echo "$0: copying bitcoin.conf to /home/bitcoin/.bitcoin and /root/.bitcoin"
  cp /etc/bitcoin/bitcoin.conf /home/bitcoin/.bitcoin/bitcoin.conf
  cp /etc/bitcoin/bitcoin.conf /root/.bitcoin/bitcoin.conf
  chown bitcoin:bitcoin /home/bitcoin/.bitcoin/bitcoin.conf
  # New: Also set correct ownership for the copied file in /root/.bitcoin
  chown root:root /root/.bitcoin/bitcoin.conf
  chmod 600 /home/bitcoin/.bitcoin/bitcoin.conf
  # New: Ensure the copied file in /root/.bitcoin has correct permissions.
  chmod 600 /root/.bitcoin/bitcoin.conf
fi

if [ "$1" = "bitcoind" ] || [ "$1" = "bitcoin-cli" ] || [ "$1" = "bitcoin-tx" ]; then
  echo
  exec gosu bitcoin "$@"
fi

echo
exec "$@"
