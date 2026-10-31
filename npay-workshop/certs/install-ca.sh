#!/bin/sh
# Trust the demo roots in the booted Simulator (like installing a profile on a phone).
#   sh certs/install-ca.sh          NPay's root only: the app works over HTTPS
#   sh certs/install-ca.sh proxy    also the proxy's root: now the proxy can read traffic unless the app pins
cd "$(dirname "$0")"
xcrun simctl keychain booted add-root-cert ca.crt && echo "trusted: NPay Demo Root CA"
[ "$1" = proxy ] && xcrun simctl keychain booted add-root-cert proxy-ca.crt && echo "trusted: Proxy Inspector Root CA"
exit 0
