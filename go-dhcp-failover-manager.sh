#!/bin/bash

# =====================================================================
# dhcp-failover-manager.sh - Gestore del server DHCP di backup con failover
# Autore: (Basato sul progetto originale)
# Data: Maggio 2025
# Versione: 1.0
# =====================================================================

# Verifica che lo script sia eseguito come root
if [ "$EUID" -ne 0 ]; then
    echo "Questo script deve essere eseguito come root (sudo)."
    sleep 4
    exit 1
fi

# Parametri di default
SUBNET_MASK="255.255.255.0"
DHCP_START_OFFSET=101
DHCP_END_OFFSET=250
DOMAIN_NAME="local.lan"
USE_SERVER_AS_DNS=true
CUSTOM_DNS="1.1.1.1,1.0.0.1"
CHECK_INTERVAL=30
PING_COUNT=3
PING_TIMEOUT=1

# Colori per l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[1;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Pulizia schermo
clear

# Funzioni di visualizzazione menu
show_header() {
    echo -e "${BLUE}=============================================================${NC}"
    echo -e "${BLUE}    Server DHCP di Backup con Failover Automatico            ${NC}"
    echo -e "${BLUE}=============================================================${NC}"
    echo -e " _____   _   _    _____   _____     _____          _   _                             "
    echo -e "|  _  \\ | | | |  /  ___| |  _  \\   |  ___|        (_) | |                            "
    echo -e "| | | | | |_| |  | |     | |_| |   | |___    __ _  _  | |  ___ __   __  ___   _ __  "
    echo -e "| | | | |  _  |  | |     |  ___/   |  ___|  / _\` || | | | / _ \\\\ \\ / / / _ \\ | '__| "
    echo -e "| |_| | | | | |  | |___  | |       | |     | (_| || | | || (_) |\\ V / | (_) || |    "
    echo -e "|_____/ |_| |_|  \\_____| |_|       |_|      \\__,_||_| |_| \\___/  \\_/   \\___/ |_|    "
    echo -e "${BLUE}=============================================================${NC}"
    echo -e "${BLUE}               By Michele Perani & claude ai                 ${NC}"
    echo -e "${BLUE}=============================================================${NC}"
    echo ""
}

show_main_menu() {
    clear 
    show_header
    echo -e "Questo programma installa e configura un server DHCP di backup"
    echo -e "che si attiva automaticamente quando il server DHCP principale"
    echo -e "diventa irraggiungibile e si disattiva quando torna online."
    echo ""
    echo -e "Seleziona un'operazione:"
    echo ""
    echo -e "  ${GREEN}1)${NC} Installare il server DHCP di backup"
    echo -e "  ${GREEN}2)${NC} Disinstallare il server DHCP di backup"
    echo -e "  ${GREEN}3)${NC} Verificare lo stato del sistema"
    echo -e "  ${GREEN}4)${NC} Visualizzare i log di failover"
    echo -e "  ${GREEN}5)${NC} Testare il sistema di failover"
    echo -e "  ${GREEN}6)${NC} Uscire dal programma"
    echo ""
    
    # Verifica se il sistema è già installato
    if systemctl is-active --quiet dhcp-failover.service 2>/dev/null; then
        echo -e "${GREEN}Lo stato del servizio di failover è ATTIVO${NC}"
    elif systemctl is-enabled --quiet dhcp-failover.service 2>/dev/null; then
        echo -e "${YELLOW}Lo stato del servizio di failover è INSTALLATO ma NON ATTIVO${NC}"
    else
        echo -e "${GRAY}Il servizio di failover non risulta installato nel sistema${NC}"
    fi
    
    echo ""
    read -p "Seleziona un'opzione (1-6): " main_choice
    
    case $main_choice in
        1)
            # Chiamata alla funzione di installazione
            install_dhcp_failover
            ;;
        2)
            # Chiamata alla funzione di disinstallazione
            uninstall_dhcp_failover
            ;;
        3)
            # Verifica dello stato del sistema
            check_system_status
            ;;
        4)
            # Visualizzazione dei log di failover
            view_failover_logs
            ;;
        5)
            # Test del sistema di failover
            test_failover_system
            ;;
        6)
            # Uscita dal programma
            echo -e "${YELLOW}Uscita dal programma. Arrivederci!${NC}"
            exit 0
            ;;
        *)
            # Opzione non valida
            echo -e "${RED}Opzione non valida. Riprova.${NC}"
            sleep 2
            show_main_menu
            ;;
    esac
}

# Funzione per verificare lo stato del sistema
check_system_status() {
    clear
    show_header
    echo -e "${BOLD}${CYAN}STATO DEL SISTEMA${NC}"
    echo ""
    
    # Verifica lo stato del servizio di failover
    echo -e "${BOLD}Servizio di failover:${NC}"
    if systemctl is-active --quiet dhcp-failover.service 2>/dev/null; then
        echo -e "  Stato: ${GREEN}ATTIVO${NC}"
    else
        echo -e "  Stato: ${RED}NON ATTIVO${NC}"
    fi
    
    if systemctl is-enabled --quiet dhcp-failover.service 2>/dev/null; then
        echo -e "  Avvio automatico: ${GREEN}ABILITATO${NC}"
    else
        echo -e "  Avvio automatico: ${RED}DISABILITATO${NC}"
    fi
    
    echo ""
    
    # Verifica lo stato del server DHCP
    echo -e "${BOLD}Server DHCP:${NC}"
    if systemctl is-active --quiet isc-dhcp-server 2>/dev/null; then
        echo -e "  Stato: ${GREEN}ATTIVO${NC} (il server DHCP potrebbe essere offline)"
    else
        echo -e "  Stato: ${YELLOW}NON ATTIVO${NC} (normale se il server DHCP principale è online)"
    fi
    
    # Verifica la presenza dei file di configurazione
    echo ""
    echo -e "${BOLD}File di configurazione:${NC}"
    if [ -f "/usr/local/bin/dhcp-failover.sh" ]; then
        echo -e "  Script failover: ${GREEN}PRESENTE${NC}"
    else
        echo -e "  Script failover: ${RED}MANCANTE${NC}"
    fi
    
    if [ -f "/etc/systemd/system/dhcp-failover.service" ]; then
        echo -e "  Service systemd: ${GREEN}PRESENTE${NC}"
    else
        echo -e "  Service systemd: ${RED}MANCANTE${NC}"
    fi
    
    if [ -f "/etc/dhcp/dhcpd.conf" ]; then
        echo -e "  Configurazione DHCP: ${GREEN}PRESENTE${NC}"
    else
        echo -e "  Configurazione DHCP: ${RED}MANCANTE${NC}"
    fi
    
    # Verifica della raggiungibilità del server DHCP
    echo ""
    echo -e "${BOLD}Test di connettività:${NC}"
    
    # Trova l'IP del server DHCP dal file di configurazione se esiste
    ROUTER_IP=""
    if [ -f "/usr/local/bin/dhcp-failover.sh" ]; then
        ROUTER_IP=$(grep -o 'ROUTER_IP="[0-9.]*"' /usr/local/bin/dhcp-failover.sh | cut -d'"' -f2)
    fi
    
    if [ -z "$ROUTER_IP" ]; then
        ROUTER_IP=$(ip route | grep default | awk '{print $3}' | head -n 1)
    fi
    
    if [ -n "$ROUTER_IP" ]; then
        if ping -c 1 -W 1 "$ROUTER_IP" > /dev/null 2>&1; then
            echo -e "  Router ($ROUTER_IP): ${GREEN}RAGGIUNGIBILE${NC}"
        else
            echo -e "  Router ($ROUTER_IP): ${RED}NON RAGGIUNGIBILE${NC} (il server DHCP dovrebbe essere attivo)"
        fi
    else
        echo -e "  Router: ${YELLOW}IP NON RILEVATO${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}=============================================================${NC}"
    echo ""
    read -p "Premi Enter per tornare al menu principale..." dummy
    show_main_menu
}

# Funzione per visualizzare i log di failover
view_failover_logs() {
    clear
    show_header
    echo -e "${BOLD}${CYAN}LOG DEL SISTEMA DI FAILOVER${NC}"
    echo ""
    
    if [ -f "/var/log/dhcp-failover.log" ]; then
        echo -e "${YELLOW}Ultimi 20 eventi registrati:${NC}"
        echo ""
        echo -e "${GRAY}$(tail -n 20 /var/log/dhcp-failover.log)${NC}"
        echo ""
        echo -e "${BLUE}=============================================================${NC}"
        echo -e "Per visualizzare il log completo: ${CYAN}sudo cat /var/log/dhcp-failover.log${NC}"
    else
        echo -e "${RED}Il file di log non esiste. Il sistema di failover potrebbe non essere installato.${NC}"
    fi
    
    echo ""
    read -p "Premi Enter per tornare al menu principale..." dummy
    show_main_menu
}

# Funzione per testare il sistema di failover
test_failover_system() {
    clear
    show_header
    echo -e "${BOLD}${CYAN}TEST DEL SISTEMA DI FAILOVER${NC}"
    echo ""
    
    # Trova l'IP del router dal file di configurazione
    ROUTER_IP=""
    if [ -f "/usr/local/bin/dhcp-failover.sh" ]; then
        ROUTER_IP=$(grep -o 'ROUTER_IP="[0-9.]*"' /usr/local/bin/dhcp-failover.sh | cut -d'"' -f2)
    fi
    
    if [ -z "$ROUTER_IP" ]; then
        ROUTER_IP=$(ip route | grep default | awk '{print $3}' | head -n 1)
    fi
    
    if [ -z "$ROUTER_IP" ]; then
        echo -e "${RED}Impossibile determinare l'IP del server DHCP. Test annullato.${NC}"
        echo ""
        read -p "Premi Enter per tornare al menu principale..." dummy
        show_main_menu
        return
    fi
    
    echo -e "Il test simulerà un'interruzione del server DHCP principale ($ROUTER_IP)"
    echo -e "bloccando temporaneamente la comunicazione verso di esso."
    echo ""
    echo -e "${YELLOW}ATTENZIONE:${NC} Durante il test, il server DHCP di backup dovrebbe attivarsi"
    echo -e "automaticamente. Si consiglia di eseguire questo test solo in un ambiente"
    echo -e "controllato e non durante l'utilizzo normale della rete."
    echo ""
    
    read -p "Vuoi procedere con il test? (s/n): " confirm_test
    if [[ ! $confirm_test =~ ^[Ss]$ ]]; then
        echo ""
        echo -e "${YELLOW}Test annullato.${NC}"
        echo ""
        read -p "Premi Enter per tornare al menu principale..." dummy
        show_main_menu
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Avvio del test...${NC}"
    echo ""
    
    # Stato iniziale
    echo -e "Stato iniziale del server DHCP:"
    if systemctl is-active --quiet isc-dhcp-server; then
        echo -e "  Server DHCP: ${GREEN}ATTIVO${NC}"
    else
        echo -e "  Server DHCP: ${YELLOW}NON ATTIVO${NC} (normale se il router è online)"
    fi
    
    # Blocca la comunicazione con il router
    echo ""
    echo -e "${YELLOW}Simulazione dell'interruzione del router...${NC}"
    iptables -A OUTPUT -d "$ROUTER_IP" -j DROP
    
    # Attesa per il failover
    echo -e "Attesa di 45 secondi per il failover..."
    for i in {45..1}; do
        echo -ne "\rAttesa: $i secondi rimanenti..."
        sleep 1
    done
    echo -e "\rAttesa: completata           "
    
    # Verifica dell'attivazione del server DHCP
    echo ""
    echo -e "Stato dopo l'interruzione simulata:"
    if systemctl is-active --quiet isc-dhcp-server 2>/dev/null; then
        echo -e "  Server DHCP: ${GREEN}ATTIVO${NC} (il failover ha funzionato correttamente)"
    else
        echo -e "  Server DHCP: ${RED}NON ATTIVO${NC} (il failover potrebbe non funzionare correttamente)"
    fi
    
    # Rimuovi il blocco
    echo ""
    echo -e "${YELLOW}Ripristino della connessione al router...${NC}"
    iptables -D OUTPUT -d "$ROUTER_IP" -j DROP
    
    # Attesa per il ripristino
    echo -e "Attesa di 45 secondi per il ripristino..."
    for i in {45..1}; do
        echo -ne "\rAttesa: $i secondi rimanenti..."
        sleep 1
    done
    echo -e "\rAttesa: completata           "
    
    # Verifica del ripristino
    echo ""
    echo -e "Stato dopo il ripristino:"
    if systemctl is-active --quiet isc-dhcp-server 2>/dev/null; then
        echo -e "  Server DHCP: ${RED}ANCORA ATTIVO${NC} (il ripristino potrebbe non funzionare correttamente)"
    else
        echo -e "  Server DHCP: ${GREEN}NON ATTIVO${NC} (il ripristino ha funzionato correttamente)"
    fi
    
    echo ""
    echo -e "${GREEN}Test completato.${NC}"
    
    # Visualizza gli ultimi eventi dal log
    if [ -f "/var/log/dhcp-failover.log" ]; then
        echo ""
        echo -e "${YELLOW}Ultimi eventi registrati nel log:${NC}"
        echo ""
        echo -e "${GRAY}$(tail -n 10 /var/log/dhcp-failover.log)${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}=============================================================${NC}"
    echo ""
    read -p "Premi Enter per tornare al menu principale..." dummy
    show_main_menu
}

# =====================================================================
# SEZIONE DI INSTALLAZIONE 
# =====================================================================

install_dhcp_failover() {
    clear
    show_header
    echo -e "${BOLD}${CYAN}INSTALLAZIONE SERVER DHCP DI BACKUP${NC}"
    echo ""
    
    # Verifica se il servizio è già installato
    if systemctl is-enabled --quiet dhcp-failover.service 2>/dev/null; then
        echo -e "${YELLOW}Il servizio di failover risulta già installato nel sistema.${NC}"
        echo -e "Vuoi reinstallarlo? Questa operazione sovrascriverà la configurazione esistente."
        echo ""
        read -p "Reinstallare il servizio? (s/n): " confirm_reinstall
        
        if [[ ! $confirm_reinstall =~ ^[Ss]$ ]]; then
            echo ""
            echo -e "${YELLOW}Installazione annullata.${NC}"
            echo ""
            read -p "Premi Enter per tornare al menu principale..." dummy
            show_main_menu
            return
        fi
    fi
    
    # Backup e log di installazione
    SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
    BACKUP_DIR="/var/lib/dhcp-failover-backup"
    INSTALL_TIMESTAMP=$(date +"%Y%m%d%H%M%S")
    CONFIG_FILE="$BACKUP_DIR/dhcp-failover.conf"
    INSTALLATION_LOG="$SCRIPT_DIR/dhcp-failover-installation-$INSTALL_TIMESTAMP.log"
    
    # Crea directory per i backup
    mkdir -p "$BACKUP_DIR/files-$INSTALL_TIMESTAMP"
    
    # Inizializza il log di installazione
    touch "$INSTALLATION_LOG"
    
    # Funzione per scrivere nel log di installazione
    log_installation() {
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$INSTALLATION_LOG"
    }
    
    # Funzione per mostrare messaggi informativi
    info() {
        echo -e "${BOLD}${CYAN}[INFO]${NC} $1"
        log_installation "[INFO] $1"
    }
    
    # Funzione per mostrare messaggi di successo
    success() {
        echo -e "${BOLD}${GREEN}[OK]${NC} $1"
        log_installation "[OK] $1"
    }
    
    # Funzione per mostrare messaggi di avviso
    warning() {
        echo -e "${BOLD}${YELLOW}[AVVISO]${NC} $1"
        log_installation "[AVVISO] $1"
    }
    
    # Funzione per mostrare messaggi di errore
    error() {
        echo -e "${BOLD}${RED}[ERRORE]${NC} $1"
        log_installation "[ERRORE] $1"
    }
    
    # Funzione per salvare la configurazione attuale
    save_configuration() {
        mkdir -p "$BACKUP_DIR"
        
        # Salva la configurazione in un file
        cat > "$CONFIG_FILE" << EOF
# Configurazione DHCP Failover - Salvata il $(date)
INTERFACE="$interface"
SERVER_IP="$server_ip"
ROUTER_IP="$router_ip"
MAC_ADDRESS="$mac_address"
SUBNET_MASK="$SUBNET_MASK"
DHCP_START="$dhcp_start"
DHCP_END="$dhcp_end"
DOMAIN_NAME="$DOMAIN_NAME"
USE_SERVER_AS_DNS="$USE_SERVER_AS_DNS"
CUSTOM_DNS="$CUSTOM_DNS"
CHECK_INTERVAL="$CHECK_INTERVAL"
PING_COUNT="$PING_COUNT"
PING_TIMEOUT="$PING_TIMEOUT"
INSTALL_DATE="$(date)"
INSTALL_TIMESTAMP="$INSTALL_TIMESTAMP"
EOF
        
        # Backup file di configurazione originali
        if [ -f /etc/dhcp/dhcpd.conf ]; then
            cp /etc/dhcp/dhcpd.conf "$BACKUP_DIR/files-$INSTALL_TIMESTAMP/dhcpd.conf.original"
        fi
        
        if [ -f /etc/default/isc-dhcp-server ]; then
            cp /etc/default/isc-dhcp-server "$BACKUP_DIR/files-$INSTALL_TIMESTAMP/isc-dhcp-server.original"
        fi
        
        # Salva lo stato dei servizi
        if systemctl is-active --quiet isc-dhcp-server 2>/dev/null; then
            echo "active" > "$BACKUP_DIR/files-$INSTALL_TIMESTAMP/isc-dhcp-server.state"
        else
            echo "inactive" > "$BACKUP_DIR/files-$INSTALL_TIMESTAMP/isc-dhcp-server.state"
        fi
        
        if systemctl is-enabled --quiet isc-dhcp-server 2>/dev/null; then
            echo "enabled" > "$BACKUP_DIR/files-$INSTALL_TIMESTAMP/isc-dhcp-server.enabled"
        else
            echo "disabled" > "$BACKUP_DIR/files-$INSTALL_TIMESTAMP/isc-dhcp-server.enabled"
        fi
        
        success "Configurazione attuale salvata in $CONFIG_FILE"
    }
    
    # Raccolta delle informazioni di configurazione
    info "Raccolta delle informazioni di configurazione della rete..."
    echo ""
    
    # Ottenere interfaccia primaria
    default_interface=$(ip route | grep default | awk '{print $5}' | head -n 1)
    if [ -z "$default_interface" ]; then
        # Se non c'è una route di default, prova a prendere la prima interfaccia attiva
        default_interface=$(ip -o link show up | grep -v "lo" | awk -F': ' '{print $2}' | head -n 1)
    fi
    echo -e "Interfaccia di rete da utilizzare o digitarla per cambiare [${GREEN}$default_interface${NC}]: "; read -p "" interface
    interface=${interface:-$default_interface}
    
    # Ottenere MAC address dell'interfaccia
    mac_address=$(ip link show $interface | grep -oE "([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}" | head -n 1)
    if [ -z "$mac_address" ]; then
        error "Impossibile ottenere il MAC address per l'interfaccia $interface"
        read -p "Inserisci manualmente il MAC address: " mac_address
        if [ -z "$mac_address" ]; then
            error "MAC address non valido. Installazione annullata."
            read -p "Premi Enter per tornare al menu principale..." dummy
            show_main_menu
            return
        fi
    fi
    
    # Ottenere IP del server
    current_ip=$(ip addr show $interface | grep -oE 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | awk '{print $2}' | head -n 1)
    echo -e "Indirizzo IP del nuovo server di backup o digitarlo per cambiare [${GREEN}$current_ip${NC}]: "; read -p "" server_ip
    server_ip=${server_ip:-$current_ip}
    
    # Ottenere IP del server DHCP principale (gateway)
    default_gateway=$(ip route | grep default | awk '{print $3}' | head -n 1)
    echo -e "Indirizzo IP del server DHCP principale o digitalo per cambiare [${GREEN}$default_gateway${NC}]: "; read -p "" router_ip
    router_ip=${router_ip:-$default_gateway}
    
    # Impostare range DHCP
    router_ip_prefix=$(echo $router_ip | cut -d. -f1-3)
    
    echo -e "Inizio range DHCP o digitalo per cambiare [${GREEN}$router_ip_prefix.$DHCP_START_OFFSET${NC}]: "; read -p "" dhcp_start
    dhcp_start=${dhcp_start:-$router_ip_prefix.$DHCP_START_OFFSET}
    
    echo -e "Fine range DHCP o digitalo per cambiare [${GREEN}$router_ip_prefix.$DHCP_END_OFFSET${NC}]: "; read -p "" dhcp_end
    dhcp_end=${dhcp_end:-$router_ip_prefix.$DHCP_END_OFFSET}
    
    # Configurazione DNS
CURRENT_DNS=$(grep "nameserver" /etc/resolv.conf | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')
if [ -z "$CURRENT_DNS" ]; then
    CURRENT_DNS=$CUSTOM_DNS  # Usa il DNS nei parametri di default se non rilevato
    if [ -z "$CURRENT_DNS" ]; then
        CURRENT_DNS="8.8.8.8"  # Fallback a DNS Google se non c'è nulla
    fi
fi
echo -e "Usare il DNS rilevato (${GREEN}$CURRENT_DNS${NC}) come DNS del server di backup? (s/n) [${GREEN}s${NC}]: "; read -p "" use_detected_dns
if [[ $use_detected_dns =~ ^[Nn]$ ]]; then
    # L'utente non vuole usare il DNS rilevato
    echo -e "Inserisci gli indirizzi IP dei server DNS che i client dovranno utilizzare (separati da virgola) [${GREEN}$CUSTOM_DNS${NC}]: "; read -p "" custom_dns_input
    if [ -n "$custom_dns_input" ]; then
        CUSTOM_DNS=$custom_dns_input
    fi
else
    # L'utente vuole usare il DNS rilevato
    CUSTOM_DNS=$CURRENT_DNS
fi
# Mai usare il server stesso come DNS
USE_SERVER_AS_DNS=false

    # Riepilogo della configurazione
    clear
    show_header
    echo -e "${BOLD}${YELLOW}RIEPILOGO CONFIGURAZIONE:${NC}"
    echo -e "${BOLD}${CYAN}=============================================================${NC}"
    echo -e "Interfaccia di rete:           ${BOLD}${GREEN}$interface${NC}"
    echo -e "MAC address:                   ${BOLD}${GREEN}$mac_address${NC}"
    echo -e "IP del server:                 ${BOLD}${GREEN}$server_ip${NC}"
    echo -e "IP del server DHCP principale: ${BOLD}${GREEN}$router_ip${NC}"
    echo -e "Range DHCP:                    ${BOLD}${GREEN}$dhcp_start - $dhcp_end${NC}"
    echo -e "Maschera di sottorete:         ${BOLD}${GREEN}$SUBNET_MASK${NC}"
    echo -e "Nome di dominio:               ${BOLD}${GREEN}$DOMAIN_NAME${NC}"
    if [ "$USE_SERVER_AS_DNS" = true ]; then
        echo -e "Server DNS:                    ${GREEN}$server_ip (questo server)${NC}"
    else
        if [ -n "$CUSTOM_DNS" ]; then
            echo -e "Server DNS:              ${GREEN}$CUSTOM_DNS${NC}"
        else
            echo -e "Server DNS:              ${GREEN}$router_ip (DHCP principale)${NC}"
        fi
    fi
    echo -e "Intervallo di controllo:       ${GREEN}$CHECK_INTERVAL secondi${NC}"
    echo -e "${BLUE}=============================================================${NC}"
    echo ""
    echo -e "${YELLOW}IMPORTANTE: Verificare attentamente tutti i dati sopra prima di procedere.${NC}"
    echo -e "L'installazione configurerà un server DHCP di backup che si attiverà"
    echo -e "automaticamente quando il router principale non sarà raggiungibile."
    echo ""
    
    read -p "Vuoi procedere con l'installazione? (s/n): " confirm
    if [[ ! $confirm =~ ^[Ss]$ ]]; then
        echo ""
        echo -e "${YELLOW}Installazione annullata.${NC}"
        read -p "Premi Enter per tornare al menu principale..." dummy
        show_main_menu
        return
    fi
    
    echo ""
    echo -e "${RED}ATTENZIONE: Questa operazione modificherà la configurazione di rete del sistema.${NC}"
    echo -e "${RED}Per confermare l'installazione, digita 'install':${NC}"
    read -p "> " install_confirm
    
    if [[ "$install_confirm" != "install" ]]; then
        echo ""
        echo -e "${YELLOW}Installazione annullata. Non hai digitato 'install'.${NC}"
        read -p "Premi Enter per tornare al menu principale..." dummy
        show_main_menu
        return
    fi
    
    echo ""
    echo -e "${GREEN}Installazione confermata. Avvio della procedura...${NC}"
    echo ""
    
    # Salva la configurazione
    save_configuration
    
    # Verifica se il pacchetto isc-dhcp-server è installato
    info "Verifica dei pacchetti necessari..."
    if ! dpkg -l | grep -q isc-dhcp-server; then
        info "Installazione del pacchetto isc-dhcp-server..."
        apt update
        apt install -y isc-dhcp-server
        if [ $? -ne 0 ]; then
            error "Impossibile installare isc-dhcp-server. Verifica la connessione o i repository."
            read -p "Premi Enter per tornare al menu principale..." dummy
            show_main_menu
            return
        fi
        success "Pacchetto isc-dhcp-server installato correttamente."
    else
        success "Il pacchetto isc-dhcp-server è già installato."
    fi
    
    # Configurazione del server DHCP
    info "Configurazione del server DHCP..."
    
    # Configurazione di /etc/dhcp/dhcpd.conf
    cat > /etc/dhcp/dhcpd.conf << EOF
# Configurazione globale
default-lease-time 600;
max-lease-time 7200;
authoritative;

# Disabilita l'aggiornamento DNS dinamico
ddns-update-style none;

# Subnet della rete locale
subnet $router_ip_prefix.0 netmask $SUBNET_MASK {
  range $dhcp_start $dhcp_end;
  option routers $router_ip;
EOF
    
    # Aggiungi configurazione DNS appropriata
    if [ "$USE_SERVER_AS_DNS" = true ]; then
        echo "  option domain-name-servers $server_ip;" >> /etc/dhcp/dhcpd.conf
    else
        if [ -n "$CUSTOM_DNS" ]; then
            echo "  option domain-name-servers $CUSTOM_DNS;" >> /etc/dhcp/dhcpd.conf
        else
            echo "  option domain-name-servers $router_ip;" >> /etc/dhcp/dhcpd.conf
        fi
        fi

    # Completa la configurazione DHCP
    cat >> /etc/dhcp/dhcpd.conf << EOF
  option domain-name "$DOMAIN_NAME";
  option broadcast-address $router_ip_prefix.255;
}

# Configurazione fissa per il server stesso
host server-debian {
  hardware ethernet $mac_address;
  fixed-address $server_ip;
}
EOF

    success "File di configurazione DHCP creato."
    
    # Configurazione dell'interfaccia
    info "Configurazione dell'interfaccia per il server DHCP..."
    
    # Configurazione di /etc/default/isc-dhcp-server
    cat > /etc/default/isc-dhcp-server << EOF
# Configurazione delle interfacce per isc-dhcp-server
INTERFACESv4="$interface"
INTERFACESv6=""
EOF

    success "Configurazione dell'interfaccia completata."
    
    # Creazione dello script di failover
    info "Creazione dello script di failover..."
    
    mkdir -p /var/log
    touch /var/log/dhcp-failover.log
    chmod 644 /var/log/dhcp-failover.log
    
    cat > /usr/local/bin/dhcp-failover.sh << EOF
#!/bin/bash

# Configurazione
ROUTER_IP="$router_ip"
CHECK_INTERVAL=$CHECK_INTERVAL  # Secondi tra i controlli
PING_COUNT=$PING_COUNT
PING_TIMEOUT=$PING_TIMEOUT
LOG_FILE="/var/log/dhcp-failover.log"

# Funzione per scrivere nei log
log_message() {
    echo "\$(date '+%Y-%m-%d %H:%M:%S') - \$1" >> "\$LOG_FILE"
    echo "\$(date '+%Y-%m-%d %H:%M:%S') - \$1"
}

# Funzione per verificare se il router è raggiungibile
check_router() {
    ping -c "\$PING_COUNT" -W "\$PING_TIMEOUT" "\$ROUTER_IP" > /dev/null 2>&1
    return \$?
}

# Funzione per avviare il server DHCP
start_dhcp() {
    if ! systemctl is-active --quiet isc-dhcp-server; then
        log_message "Router principale non raggiungibile. Avvio del server DHCP di backup..."
        systemctl start isc-dhcp-server
        if [ \$? -eq 0 ]; then
            log_message "Server DHCP di backup avviato con successo"
        else
            log_message "ERRORE: Impossibile avviare il server DHCP di backup"
        fi
    fi
}

# Funzione migliorata per fermare il server DHCP
stop_dhcp() {
    if systemctl is-active --quiet isc-dhcp-server || pgrep dhcpd > /dev/null; then
        log_message "Router principale tornato online. Arresto del server DHCP di backup..."
        
        # Ferma il servizio tramite systemctl
        systemctl stop isc-dhcp-server
        
        # Verifica se ci sono ancora processi dhcpd in esecuzione
        if pgrep dhcpd > /dev/null; then
            log_message "Processi dhcpd residui rilevati, terminazione forzata..."
            
            # Termina forzatamente qualsiasi processo dhcpd rimasto
            pkill -9 dhcpd
            
            # Breve pausa per dare tempo al sistema di terminare i processi
            sleep 1
            
            # Verifica finale
            if pgrep dhcpd > /dev/null; then
                log_message "AVVISO: Impossibile terminare tutti i processi dhcpd"
            else
                log_message "Tutti i processi dhcpd terminati con successo"
            fi
        else
            log_message "Server DHCP di backup arrestato con successo"
        fi
    fi
}

# Loop principale
while true; do
    if check_router; then
        # Router raggiungibile, disattiva il server DHCP se attivo
        stop_dhcp
    else
        # Router non raggiungibile, attiva il server DHCP se non attivo
        start_dhcp
    fi
    
    # Aspetta prima del prossimo controllo
    sleep "\$CHECK_INTERVAL"
done
EOF

    chmod +x /usr/local/bin/dhcp-failover.sh
    
    success "Script di failover creato."
    
    # Creazione del servizio systemd
    info "Creazione del servizio systemd per il failover..."
    
    cat > /etc/systemd/system/dhcp-failover.service << EOF
[Unit]
Description=DHCP Failover Monitor Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/dhcp-failover.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    success "File di servizio systemd creato."
    
    # Configurazione dei servizi
    info "Configurazione dei servizi..."
    
    # Verifica la configurazione del server DHCP
    if dhcpd -t -cf /etc/dhcp/dhcpd.conf; then
        success "Configurazione DHCP verificata correttamente."
    else
        error "Errore nella configurazione DHCP. Verificare il file /etc/dhcp/dhcpd.conf."
        read -p "Vuoi continuare comunque? (s/n): " continue_anyway
        if [[ ! $continue_anyway =~ ^[Ss]$ ]]; then
            error "Installazione interrotta. Correggere gli errori e riprovare."
            read -p "Premi Enter per tornare al menu principale..." dummy
            show_main_menu
            return
        fi
    fi
    
    # Disabilita l'avvio automatico del server DHCP
    systemctl disable isc-dhcp-server
    systemctl stop isc-dhcp-server
    
    # Abilita e avvia il servizio di failover
    systemctl daemon-reload
    systemctl enable dhcp-failover.service
    systemctl start dhcp-failover.service
    
    success "Servizi configurati correttamente."
    
    # Verifica finale
    info "Verificando che il servizio di failover sia in esecuzione..."
    sleep 2
    
    if systemctl is-active --quiet dhcp-failover.service 2>/dev/null; then
        success "Il servizio di failover è attivo e in esecuzione."
    else
        error "Il servizio di failover non si è avviato correttamente."
        echo ""
        echo "Controlla i log con: journalctl -u dhcp-failover.service"
    fi
    
    # Creazione del report finale di installazione
    info "Creazione del report finale di installazione..."
    
    # Ottieni informazioni sui servizi
    DHCP_SERVICE_STATUS=$(systemctl is-active isc-dhcp-server)
    FAILOVER_SERVICE_STATUS=$(systemctl is-active dhcp-failover.service)
    
    # Crea report finale
    REPORT_FILE="$SCRIPT_DIR/dhcp-failover-report-$INSTALL_TIMESTAMP.txt"
    cat > "$REPORT_FILE" << EOF
=====================================================================
   REPORT DI INSTALLAZIONE - SERVER DHCP FAILOVER
=====================================================================
Data e ora: $(date)

CONFIGURAZIONE DI RETE:
- Interfaccia: $interface
- MAC address: $mac_address
- IP del server: $server_ip
- IP del router: $router_ip
- Subnet mask: $SUBNET_MASK

CONFIGURAZIONE DHCP:
- Range DHCP: $dhcp_start - $dhcp_end
- Nome di dominio: $DOMAIN_NAME
- Server DNS: $(if [ "$USE_SERVER_AS_DNS" = true ]; then echo "$server_ip (questo server)"; elif [ -n "$CUSTOM_DNS" ]; then echo "$CUSTOM_DNS"; else echo "$router_ip (router)"; fi)

CONFIGURAZIONE FAILOVER:
- Intervallo di controllo: $CHECK_INTERVAL secondi
- Ping count: $PING_COUNT
- Ping timeout: $PING_TIMEOUT

STATO DEI SERVIZI:
- Server DHCP (isc-dhcp-server): $DHCP_SERVICE_STATUS
- Servizio failover (dhcp-failover.service): $FAILOVER_SERVICE_STATUS

FILE INSTALLATI:
- Script di failover: /usr/local/bin/dhcp-failover.sh
- Servizio systemd: /etc/systemd/system/dhcp-failover.service
- Configurazione DHCP: /etc/dhcp/dhcpd.conf
- Configurazione interfacce: /etc/default/isc-dhcp-server

BACKUP:
- Directory di backup: $BACKUP_DIR
- Configurazione salvata: $CONFIG_FILE
- Backup timestamp: $INSTALL_TIMESTAMP

LOG COMPLETO:
Il log completo dell'installazione è disponibile in:
$INSTALLATION_LOG

COMANDI UTILI:
- Verificare lo stato del servizio DHCP: sudo systemctl status isc-dhcp-server
- Verificare lo stato del servizio failover: sudo systemctl status dhcp-failover.service
- Controllare i log di failover: sudo tail -f /var/log/dhcp-failover.log
- Simulare un'interruzione del router: sudo iptables -A OUTPUT -d $router_ip -j DROP
- Annullare la simulazione: sudo iptables -D OUTPUT -d $router_ip -j DROP

=====================================================================
EOF

    success "Report di installazione creato in: $REPORT_FILE"
    
    # Mostra riepilogo finale
    echo ""
    echo -e "${GREEN}======================================================================${NC}"
    echo -e "${GREEN}              INSTALLAZIONE COMPLETATA CON SUCCESSO                 ${NC}"
    echo -e "${GREEN}======================================================================${NC}"
    echo ""
    echo -e "Il server DHCP di backup è stato configurato correttamente."
    echo -e "Stato attuale: ${CYAN}Server di failover attivo, in attesa di eventi${NC}"
    echo ""
    echo -e "Un report dettagliato dell'installazione è stato salvato in:"
    echo -e "${BLUE}$REPORT_FILE${NC}"
    echo ""
    echo -e "${YELLOW}PROMEMORIA:${NC}"
    echo -e "- Il server DHCP di backup si attiverà automaticamente quando"
    echo -e "  il router principale ($router_ip) non sarà raggiungibile"
    echo -e "- I log del sistema di failover sono disponibili in: ${BLUE}/var/log/dhcp-failover.log${NC}"
    echo -e "- Per controllare lo stato: ${BLUE}sudo systemctl status dhcp-failover.service${NC}"
    echo ""
    echo -e "${GREEN}Per effettuare un test del sistema di failover, seleziona l'opzione${NC}"
    echo -e "${GREEN}'Testare il sistema di failover' dal menu principale.${NC}"
    echo ""
    
    read -p "Premi Enter per tornare al menu principale..." dummy
    show_main_menu
}

# =====================================================================
# SEZIONE DI DISINSTALLAZIONE
# =====================================================================

uninstall_dhcp_failover() {
    clear
    show_header
    echo -e "${BOLD}${CYAN}DISINSTALLAZIONE SERVER DHCP DI BACKUP${NC}"
    echo ""
    
    # Verifica se il servizio è installato
    if ! systemctl is-enabled --quiet dhcp-failover.service 2>/dev/null && ! [ -f "/usr/local/bin/dhcp-failover.sh" ]; then
        echo -e "${YELLOW}Il servizio di failover non risulta installato nel sistema.${NC}"
        echo ""
        read -p "Premi Enter per tornare al menu principale..." dummy
        show_main_menu
        return
    fi
    
    echo -e "${YELLOW}Attenzione: Questa operazione rimuoverà il server DHCP di backup e tutti i file di configurazione associati.${NC}"
    echo ""
    
    # Backup directory
    BACKUP_DIR="/var/lib/dhcp-failover-backup"
    
    # Verifica se esistono backup
    if [ -d "$BACKUP_DIR" ] && [ -n "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        echo -e "${GREEN}Sono stati trovati backup di configurazioni precedenti.${NC}"
        echo -e "È possibile ripristinare una configurazione precedente durante la disinstallazione."
        echo ""
        echo -e "Opzioni disponibili:"
        echo -e "  ${GREEN}1)${NC} Disinstallare e ripristinare una configurazione precedente"
        echo -e "  ${GREEN}2)${NC} Disinstallare completamente senza ripristino"
        echo -e "  ${GREEN}3)${NC} Annullare e tornare al menu principale"
        echo ""
        
        read -p "Seleziona un'opzione (1-3): " uninstall_option
        
        case $uninstall_option in
            1)
                restore_previous_configuration
                ;;
            2)
                confirm_complete_uninstall
                ;;
            3)
                echo ""
                echo -e "${YELLOW}Disinstallazione annullata.${NC}"
                echo ""
                read -p "Premi Enter per tornare al menu principale..." dummy
                show_main_menu
                return
                ;;
            *)
                echo -e "${RED}Opzione non valida. Disinstallazione annullata.${NC}"
                echo ""
                read -p "Premi Enter per tornare al menu principale..." dummy
                show_main_menu
                return
                ;;
        esac
    else
        # Nessun backup trovato, procedi con la disinstallazione completa
        confirm_complete_uninstall
    fi
}

# Funzione per confermare la disinstallazione completa
confirm_complete_uninstall() {
    echo ""
    echo -e "${RED}ATTENZIONE: Stai per disinstallare completamente il server DHCP di backup.${NC}"
    echo -e "${RED}Non ci sono backup disponibili o hai scelto di non ripristinare.${NC}"
    echo -e "${RED}Questa operazione rimuoverà:${NC}"
    echo -e "  - Lo script di failover (/usr/local/bin/dhcp-failover.sh)"
    echo -e "  - Il servizio systemd (dhcp-failover.service)"
    echo -e "  - La configurazione DHCP personalizzata"
    echo ""
    echo -e "${RED}Per confermare la disinstallazione, digita 'uninstall':${NC}"
    read -p "> " uninstall_confirm
    
    if [[ "$uninstall_confirm" != "uninstall" ]]; then
        echo ""
        echo -e "${YELLOW}Disinstallazione annullata. Non hai digitato 'uninstall'.${NC}"
        echo ""
        read -p "Premi Enter per tornare al menu principale..." dummy
        show_main_menu
        return
    fi
    
    echo ""
    echo -e "${GREEN}Disinstallazione confermata. Avvio della procedura...${NC}"
    echo ""
    
    perform_complete_uninstall
}

# Funzione per eseguire la disinstallazione completa
perform_complete_uninstall() {
    # Funzioni di log
    info() {
        echo -e "${BOLD}${CYAN}[INFO]${NC} $1"
    }
    
    success() {
        echo -e "${BOLD}${GREEN}[OK]${NC} $1"
    }
    
    warning() {
        echo -e "${BOLD}${YELLOW}[AVVISO]${NC} $1"
    }
    
    error() {
        echo -e "${BOLD}${RED}[ERRORE]${NC} $1"
    }
    
    # Arresta e disabilita i servizi
    info "Arresto e disabilitazione dei servizi..."
    
    systemctl stop dhcp-failover.service 2>/dev/null
    systemctl disable dhcp-failover.service 2>/dev/null
    systemctl stop isc-dhcp-server 2>/dev/null
    
    success "Servizi arrestati e disabilitati."
    
    # Rimuovi i file di configurazione
    info "Rimozione dei file di configurazione..."
    
    rm -f /usr/local/bin/dhcp-failover.sh
    rm -f /etc/systemd/system/dhcp-failover.service
    
    # Non rimuoviamo completamente /etc/dhcp/dhcpd.conf e /etc/default/isc-dhcp-server
    # ma li ripristiniamo a uno stato minimo se non ci sono backup
    
    # Configurazione minima di dhcpd.conf
    cat > /etc/dhcp/dhcpd.conf << EOF
# Configurazione minima di isc-dhcp-server
# Questo file è stato ripristinato dalla procedura di disinstallazione di dhcp-failover

# Configurazione globale predefinita
default-lease-time 600;
max-lease-time 7200;
ddns-update-style none;

# Per configurare questo server DHCP, modificare questo file
# Esempio di configurazione di una subnet:
#
# subnet 192.168.1.0 netmask 255.255.255.0 {
#   range 192.168.1.100 192.168.1.200;
#   option routers 192.168.1.1;
#   option domain-name-servers 192.168.1.1;
# }
EOF

    # Configurazione minima di isc-dhcp-server
    cat > /etc/default/isc-dhcp-server << EOF
# Configurazione minima di isc-dhcp-server
# Questo file è stato ripristinato dalla procedura di disinstallazione di dhcp-failover

# Specificare qui le interfacce su cui il server DHCP deve ascoltare
INTERFACESv4=""
INTERFACESv6=""
EOF

    success "File di configurazione rimossi o ripristinati allo stato minimo."
    
    # Ricarica systemd
    systemctl daemon-reload
    
    # Crea un report di disinstallazione
    UNINSTALL_TIMESTAMP=$(date +"%Y%m%d%H%M%S")
    UNINSTALL_REPORT="/var/log/dhcp-failover-uninstall-$UNINSTALL_TIMESTAMP.log"
    
    cat > "$UNINSTALL_REPORT" << EOF
=====================================================================
   REPORT DI DISINSTALLAZIONE - SERVER DHCP FAILOVER
=====================================================================
Data e ora: $(date)

OPERAZIONI ESEGUITE:
- Servizio dhcp-failover.service arrestato e disabilitato
- File /usr/local/bin/dhcp-failover.sh rimosso
- File /etc/systemd/system/dhcp-failover.service rimosso
- File /etc/dhcp/dhcpd.conf ripristinato allo stato minimo
- File /etc/default/isc-dhcp-server ripristinato allo stato minimo

NOTA: Il pacchetto isc-dhcp-server è stato mantenuto nel sistema.
Per rimuoverlo completamente, eseguire: sudo apt remove isc-dhcp-server

=====================================================================
EOF

    success "Report di disinstallazione creato in: $UNINSTALL_REPORT"
    
    # Messaggi finali
    echo ""
    echo -e "${GREEN}======================================================================${NC}"
    echo -e "${GREEN}            DISINSTALLAZIONE COMPLETATA CON SUCCESSO                ${NC}"
    echo -e "${GREEN}======================================================================${NC}"
    echo ""
    echo -e "Il server DHCP di backup è stato disinstallato correttamente."
    echo -e "Un report dettagliato della disinstallazione è stato salvato in:"
    echo -e "${BLUE}$UNINSTALL_REPORT${NC}"
    echo ""
    echo -e "${YELLOW}NOTA:${NC}"
    echo -e "- Il pacchetto isc-dhcp-server è stato mantenuto nel sistema."
    echo -e "- Se desideri rimuoverlo completamente, esegui: ${BLUE}sudo apt remove isc-dhcp-server${NC}"
    echo -e "- La directory di backup ${BLUE}$BACKUP_DIR${NC} non è stata rimossa."
    echo -e "  Puoi rimuoverla manualmente con: ${BLUE}sudo rm -rf $BACKUP_DIR${NC}"
    echo ""
    
    read -p "Premi Enter per tornare al menu principale..." dummy
    show_main_menu
}

# Funzione per ripristinare una configurazione precedente
restore_previous_configuration() {
    clear
    show_header
    echo -e "${BOLD}${CYAN}RIPRISTINO DI UNA CONFIGURAZIONE PRECEDENTE${NC}"
    echo ""
    
    BACKUP_DIR="/var/lib/dhcp-failover-backup"
    
    # Elenca i backup disponibili
    echo -e "Backup disponibili:"
    echo ""
    
    BACKUP_DIRS=$(ls -d $BACKUP_DIR/files-* 2>/dev/null)
    if [ -z "$BACKUP_DIRS" ]; then
        error "Nessun backup trovato. Impossibile ripristinare il sistema."
        echo ""
        read -p "Premi Enter per tornare al menu principale..." dummy
        show_main_menu
        return
    fi
    
    # Crea un array di backup con data e ora
    declare -a BACKUP_LIST=()
    i=1
    for dir in $BACKUP_DIRS; do
        timestamp=${dir##*-}
        year=${timestamp:0:4}
        month=${timestamp:4:2}
        day=${timestamp:6:2}
        hour=${timestamp:8:2}
        min=${timestamp:10:2}
        sec=${timestamp:12:2}
        
        formatted_date="$day/$month/$year $hour:$min:$sec"
        BACKUP_LIST+=("$i) $formatted_date - $dir")
        ((i++))
    done
    
    # Mostra l'elenco dei backup
    for item in "${BACKUP_LIST[@]}"; do
        echo -e "${GREEN}$item${NC}"
    done
    
    echo ""
    read -p "Seleziona il backup da ripristinare (1-$((i-1)), 0 per annullare): " selection
    
    if [ "$selection" -eq 0 ]; then
        echo -e "${YELLOW}Ripristino annullato.${NC}"
        echo ""
        read -p "Premi Enter per tornare al menu principale..." dummy
        show_main_menu  # Torna al menu principale, NON procedere con la disinstallazione
        return
    fi
    
    # Ottieni il percorso del backup selezionato
    selected_index=$((selection-1))
    selected_backup=$(echo "$BACKUP_DIRS" | tr ' ' '\n' | sed -n "$((selected_index+1))p")
    
    echo ""
    echo -e "${RED}ATTENZIONE: Questa operazione ripristinerà il sistema allo stato precedente all'installazione.${NC}"
    echo -e "${RED}Per confermare il ripristino, digita 'restore':${NC}"
    read -p "> " restore_confirm
    
    if [[ "$restore_confirm" != "restore" ]]; then
        echo ""
        echo -e "${YELLOW}Ripristino annullato. Non hai digitato 'restore'.${NC}"
        echo ""
        confirm_complete_uninstall
        return
    fi
    
    echo ""
    echo -e "${GREEN}Ripristino confermato. Avvio della procedura...${NC}"
    echo ""
    
    # Funzioni di log
    info() {
        echo -e "${BOLD}${CYAN}[INFO]${NC} $1"
    }
    
    success() {
        echo -e "${BOLD}${GREEN}[OK]${NC} $1"
    }
    
    warning() {
        echo -e "${BOLD}${YELLOW}[AVVISO]${NC} $1"
    }
    
    error() {
        echo -e "${BOLD}${RED}[ERRORE]${NC} $1"
    }
    
    # Fermiamo i servizi
    info "Arresto dei servizi..."
    systemctl stop dhcp-failover.service 2>/dev/null
    systemctl stop isc-dhcp-server 2>/dev/null
    
    # Rimuoviamo i file creati durante l'installazione
    info "Rimozione dei file di configurazione..."
    rm -f /usr/local/bin/dhcp-failover.sh
    rm -f /etc/systemd/system/dhcp-failover.service
    
    # Ripristinando i file di configurazione originali
    info "Ripristino dei file di configurazione originali..."
    if [ -f "$selected_backup/dhcpd.conf.original" ]; then
        cp "$selected_backup/dhcpd.conf.original" /etc/dhcp/dhcpd.conf
        success "File dhcpd.conf ripristinato."
    else
        warning "File dhcpd.conf.original non trovato nel backup. Creazione di un file minimo..."
        cat > /etc/dhcp/dhcpd.conf << EOF
# Configurazione minima di isc-dhcp-server
# Questo file è stato ripristinato dalla procedura di disinstallazione di dhcp-failover

# Configurazione globale predefinita
default-lease-time 600;
max-lease-time 7200;
ddns-update-style none;

# Per configurare questo server DHCP, modificare questo file
# Esempio di configurazione di una subnet:
#
# subnet 192.168.1.0 netmask 255.255.255.0 {
#   range 192.168.1.100 192.168.1.200;
#   option routers 192.168.1.1;
#   option domain-name-servers 192.168.1.1;
# }
EOF
    fi
    
    if [ -f "$selected_backup/isc-dhcp-server.original" ]; then
        cp "$selected_backup/isc-dhcp-server.original" /etc/default/isc-dhcp-server
        success "File isc-dhcp-server ripristinato."
    else
        warning "File isc-dhcp-server.original non trovato nel backup. Creazione di un file minimo..."
        cat > /etc/default/isc-dhcp-server << EOF
# Configurazione minima di isc-dhcp-server
# Questo file è stato ripristinato dalla procedura di disinstallazione di dhcp-failover

# Specificare qui le interfacce su cui il server DHCP deve ascoltare
INTERFACESv4=""
INTERFACESv6=""
EOF
    fi
    
    # Ripristino dello stato originale dei servizi
    info "Ripristino dello stato dei servizi..."
    if [ -f "$selected_backup/isc-dhcp-server.enabled" ]; then
        if [ "$(cat "$selected_backup/isc-dhcp-server.enabled")" == "enabled" ]; then
            systemctl enable isc-dhcp-server
            success "Avvio automatico del server DHCP abilitato."
        else
            systemctl disable isc-dhcp-server
            success "Avvio automatico del server DHCP disabilitato."
        fi
    fi
    
    if [ -f "$selected_backup/isc-dhcp-server.state" ]; then
        if [ "$(cat "$selected_backup/isc-dhcp-server.state")" == "active" ]; then
            systemctl start isc-dhcp-server
            success "Server DHCP avviato."
        else
            success "Server DHCP mantenuto spento."
        fi
    fi
    
    systemctl daemon-reload
    
    # Crea un report di ripristino
    RESTORE_TIMESTAMP=$(date +"%Y%m%d%H%M%S")
    RESTORE_REPORT="/var/log/dhcp-failover-restore-$RESTORE_TIMESTAMP.log"
    
    cat > "$RESTORE_REPORT" << EOF
=====================================================================
   REPORT DI RIPRISTINO - SERVER DHCP FAILOVER
=====================================================================
Data e ora: $(date)

OPERAZIONI ESEGUITE:
- Servizio dhcp-failover.service rimosso
- File /usr/local/bin/dhcp-failover.sh rimosso
- File /etc/systemd/system/dhcp-failover.service rimosso
- File di configurazione ripristinati dal backup: $selected_backup
- Stato dei servizi ripristinato come nell'installazione originale

NOTA: Il pacchetto isc-dhcp-server è stato mantenuto nel sistema.
Per rimuoverlo completamente, eseguire: sudo apt remove isc-dhcp-server

=====================================================================
EOF

    success "Report di ripristino creato in: $RESTORE_REPORT"
    
    # Messaggi finali
    echo ""
    echo -e "${GREEN}======================================================================${NC}"
    echo -e "${GREEN}              RIPRISTINO COMPLETATO CON SUCCESSO                   ${NC}"
    echo -e "${GREEN}======================================================================${NC}"
    echo ""
    echo -e "Il sistema è stato ripristinato allo stato precedente all'installazione."
    echo -e "Un report dettagliato del ripristino è stato salvato in:"
    echo -e "${BLUE}$RESTORE_REPORT${NC}"
    echo ""
    echo -e "${YELLOW}NOTA:${NC}"
    echo -e "- I backup dell'installazione sono stati mantenuti in ${BLUE}$BACKUP_DIR${NC}"
    echo -e "  e possono essere utili per riferimenti futuri."
    echo ""
    
    read -p "Premi Enter per tornare al menu principale..." dummy
    show_main_menu
}
# Avvio del programma
show_main_menu
