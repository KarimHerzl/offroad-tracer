# ============================================================
#  Offroad Planner — server BRouter per il cloud (Render)
#  Contiene: BRouter + tessere dati (Nord/Centro Italia, arco
#  alpino, Francia centro-orientale, Inghilterra sud e Galles,
#  Inghilterra orientale)
#  + profili "offroad-*".
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
# 3) TESSERE DATI — ogni file copre 5°x5°. Se un percorso tocca anche
#    solo per un tratto un riquadro non presente, BRouter risponde HTTP 400
#    col messaggio "datafile XXX.rd5 not found": e' quello il modo per
#    capire subito quale tessera manca, senza tirare a indovinare.
#      E5_N45  : Nord Italia sopra il 45° parallelo, arco alpino, Giura
#      E5_N40  : Piemonte sud, Liguria, Toscana, Provenza, Corsica
#      E10_N45 : Veneto, Friuli, Trentino, Austria sud, Slovenia
#      E10_N40 : Emilia est, Marche, Abruzzo, Adriatico
#      E0_N45  : Borgogna, Loira, Massiccio Centrale nord   <-- aggiunta
#      E0_N40  : Cévennes, Tarn, Pirenei orientali          <-- aggiunta
#      W5_N50  : Inghilterra centro-sud e Galles a ovest di Greenwich
#                (Ridgeway, Wessex, Cotswolds, Peak District, Snowdonia,
#                 Isola di Man). Aggiunta il 31/07/2026
#      E0_N50  : Inghilterra a EST di Greenwich - Kent, Sussex orientale,
#                Essex, East Anglia, Lincolnshire. Serve a chi parte da
#                Londra o dal lato est: senza, li BRouter risponde 400 con
#                "datafile E0_N50.rd5 not found".  <-- aggiunta ora
#                NB: copre anche il Passo di Calais e le Fiandre, quindi da
#                oggi un percorso Calais-Dunkerque verrebbe calcolato. Il
#                profilo pero' resta quello italiano, perche' la scelta si
#                fa sul punto di partenza e Calais e' escluso dal riquadro UK.
#    Non coperti: Bretagna/Normandia (serve W5_N45).
#    Per il resto del Regno Unito servirebbero: W10_N50 (Cornovaglia, Galles
#    occidentale), W5_N55 (Inghilterra del nord, Lowlands scozzesi).
#    Ogni tessera in piu' pesa su disco e RAM: sul piano gratuito di Render
#    lo spazio e' stretto, e W5_N50 e' densa perche' contiene Londra.
#    Se compaiono crash su percorsi lunghi, togliere una tessera non usata
#    (es. E10_N40) prima di pensare a un bug.
RUN cd segments4 \
    && wget -q https://brouter.de/brouter/segments4/E5_N45.rd5 \
    && wget -q https://brouter.de/brouter/segments4/E5_N40.rd5 \
    && wget -q https://brouter.de/brouter/segments4/E10_N45.rd5 \
    && wget -q https://brouter.de/brouter/segments4/E10_N40.rd5 \
    && wget -q https://brouter.de/brouter/segments4/E0_N45.rd5 \
    && wget -q https://brouter.de/brouter/segments4/E0_N40.rd5 \
    && wget -q https://brouter.de/brouter/segments4/W5_N50.rd5 \
    && wget -q https://brouter.de/brouter/segments4/E0_N50.rd5
# 4) il NOSTRO profilo
COPY offroad-*.brf profiles2/
# 5) proxy nginx + avvio
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start.sh /opt/brouter/start.sh
RUN chmod +x /opt/brouter/start.sh
ENV PORT=10000
EXPOSE 10000
CMD ["/opt/brouter/start.sh"]
