#!/bin/sh
# Demo certificates for localhost (demo only: never ship these keys).
#   ca.crt      "NPay Demo Root CA": stands in for a public CA; the Simulator trusts it (install-ca.sh)
#   server.p12  localhost, signed by the NPay CA: the real server (port 8443)
#   proxy-ca.crt / proxy.p12  "Proxy Inspector Root CA" + localhost: an inspecting proxy (port 8444),
#               like Charles or mitmproxy whose root the user installed
# Prints the pins (SHA-256 of each public key, base64) for NSPinnedDomains in NPayRN/ios/NPayRN/Info.plist (Lab 10).
set -e
cd "$(dirname "$0")"
JAVA_HOME=${JAVA_HOME:-$(ls -d ~/.local/jdk/jdk-21*/Contents/Home 2>/dev/null | head -1)}
KT="$JAVA_HOME/bin/keytool"
P=npaydemo
rm -f *.p12 *.crt
ca() {  # ca FILE NAME
  "$KT" -genkeypair -alias ca -keyalg EC -groupname secp256r1 -dname "CN=$2" -ext bc:c -validity 800 -keystore "$1.p12" -storepass $P
  "$KT" -exportcert -alias ca -keystore "$1.p12" -storepass $P -rfc -file "$1.crt"
}
leaf() {  # leaf FILE CA
  "$KT" -genkeypair -alias npay -keyalg EC -groupname secp256r1 -dname "CN=localhost" -validity 365 -keystore "$1.p12" -storepass $P
  "$KT" -certreq -alias npay -keystore "$1.p12" -storepass $P \
    | "$KT" -gencert -alias ca -keystore "$2.p12" -storepass $P -rfc -validity 365 \
        -ext SAN=dns:localhost,ip:127.0.0.1 -ext EKU=serverAuth -ext KU=digitalSignature > "$1.crt"
  "$KT" -importcert -alias ca -file "$2.crt" -keystore "$1.p12" -storepass $P -noprompt
  "$KT" -importcert -alias npay -file "$1.crt" -keystore "$1.p12" -storepass $P -noprompt
}
ca ca "NPay Demo Root CA"
leaf server ca
ca proxy-ca "Proxy Inspector Root CA"
leaf proxy proxy-ca
# the SPKI pin: SHA-256 of the DER SubjectPublicKeyInfo, base64 (what NSPinnedLeafIdentities / NSPinnedCAIdentities expect)
pin() { openssl x509 -in "$1" -pubkey -noout | openssl pkey -pubin -outform DER | openssl dgst -sha256 -binary | base64; }
echo "server pin $(pin server.crt)"
echo "CA     pin $(pin ca.crt)"
echo "proxy  pin $(pin proxy.crt)"
