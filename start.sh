#!/usr/bin/env bash
set -e
cd /opt/brouter

# trova il jar di BRouter ovunque sia finito dentro dist/
JAR=$(ls dist/*all*.jar dist/brouter*.jar dist/**/brouter*.jar 2>/dev/null | head -n1)
LIB=$(dirname "$JAR")/lib

echo "== Avvio BRouter =="
echo "jar: $JAR"
# avvia il motore in background sulla porta interna 17777
java -Xmx420m -cp "$JAR:$LIB/*" btools.server.RouteServer segments4 profiles2 customprofiles 17777 1 &

# aspetta che BRouter sia su
sleep 5

echo "== Avvio nginx su porta $PORT =="
envsubst '$PORT' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
nginx -g 'daemon off;'
