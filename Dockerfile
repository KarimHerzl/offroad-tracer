# ============================================================
#  Offroad Planner â€” server BRouter per il cloud (Render)
#  Contiene: BRouter + tessera dati E5_N45 (Nord Italia +
#  confine alpino francese) + profilo "massimizza sterrato".
#  Un nginx davanti fa da proxy e risolve la faccenda CORS.
# ============================================================
FROM eclipse-temurin:17-jre

RUN apt-get update && apt-get install -y wget unzip nginx gettext-base \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/brouter

# 1) BRouter (jar + cartella lib).  Se al build il nome del file .zip
#    risultasse diverso, si corregge solo questa riga (vedi README).
RUN wget -q "https://github.com/abrensch/brouter/releases/download/v1.7.9/brouter-1.7.9.zip" -O brouter.zip \
    && unzip -o brouter.zip -d dist && rm brouter.zip

# 2) cartelle di lavoro
RUN mkdir -p segments4 profiles2 customprofiles

# 3) TESSERA DATI â€” per ora solo Nord Italia + confine alpino (leggera).
#    Per aggiungere costa/Nord-Est, scommenta le righe sotto.
RUN cd segments4 \
    && wget -q https://brouter.de/brouter/segments4/E5_N45.rd5 \
    && wget -q https://brouter.de/brouter/segments4/E5_N40.rd5 \
    && wget -q https://brouter.de/brouter/segments4/E10_N45.rd5 \
    && wget -q https://brouter.de/brouter/segments4/E10_N40.rd5

# 4) il NOSTRO profilo
COPY offroad-max*.brf profiles2/

# 5) proxy nginx + avvio
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start.sh /opt/brouter/start.sh
RUN chmod +x /opt/brouter/start.sh

ENV PORT=10000
EXPOSE 10000
CMD ["/opt/brouter/start.sh"]
