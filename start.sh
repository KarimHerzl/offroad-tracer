#!/usr/bin/env bash
set -e
cd /opt/brouter
 
# trova il jar di BRouter (anche se e' dentro una sottocartella con la versione)
JAR=$(ls dist/*all*.jar dist/**/*all*.jar dist/brouter*.jar dist/**/brouter*.jar 2>/dev/null | head -n1)
BASE=$(dirname "$JAR")
LIB="$BASE/lib"
 
# La distribuzione porta con se' lookups.dat (il dizionario dei tag) e i profili
# standard. Li copiamo nella nostra profiles2 SENZA sovrascrivere offroad-max.brf,
# cosi' BRouter trova sia il dizionario sia i profili (incluso il nostro).
cp -rn "$BASE"/profiles2/* profiles2/ 2>/dev/null || true
 
echo "== Avvio BRouter =="
echo "jar: $JAR"
echo "profili disponibili:"; ls profiles2/*.brf 2>/dev/null
# avvia il motore in background sulla porta interna 17777
java -Xmx420m -cp "$JAR:$LIB/*" btools.server.RouteServer segments4 profiles2 customprofiles 17777 1 &
 
sleep 5
echo "== Avvio nginx su porta $PORT =="
envsubst '$PORT' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
nginx -g 'daemon off;'
 
