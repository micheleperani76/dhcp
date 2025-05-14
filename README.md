# DHCP Failover Manager
## Automatic Backup System for DHCP Servers

## Overview

The **DHCP Failover Manager** is a bash solution designed for Debian Linux environments that provides an automatic DHCP backup server. When the primary DHCP server (typically the router) becomes unreachable, the system autonomously activates a secondary DHCP server, ensuring service continuity in the local network.

---

## 🌟 Key Features

- **Automatic monitoring** of the primary DHCP server
- **Dynamic activation/deactivation** of the backup server
- **Customizable configuration** of IP ranges, DNS, and other settings
- **Detailed logging** of all failover events
- **Complete backups** of original configurations
- **Intuitive user interface** for management and configuration
- **Integrated testing** functionality

---

## 🛠️ System Requirements

- **OS:** Debian 12 or Debian-based distributions
- **Privileges:** Root access
- **Packages:** isc-dhcp-server (automatically installed)
- **Network:** Static IP on the backup server

---

## ⚙️ System Architecture

```
                   ┌───────────────┐
                   │ Primary DHCP  │
                   │    Server     │◄────┐
                   │   (Router)    │     │
                   └───────────────┘     │ Periodic
                           ▲             │ ping
                           │             │
                           ×             │
                      Interruption       │
                           │             │
                           ▼             │
┌───────────────────────────────────────┐│
│ Debian Server                         ││
│                                       ││
│  ┌─────────────────────────────────┐  ││
│  │ DHCP Failover Service           │  ││
│  │                                 │  ││
│  │  ┌─────────────┐ ┌───────────┐ │  ││
│  │  │  Monitor    │ │ isc-dhcp- │ │  ││
│  │  │  Script     │ │  server   │ │  ││
│  │  └─────────────┘ └───────────┘ │  ││
│  └─────────────────────────────────┘  ││
└───────────────────────────────────────┘┘
```

---

## 🚀 How It Works

1. A bash script running as a systemd service continuously monitors the primary DHCP server via ping
2. If the primary server doesn't respond, the system activates the backup DHCP server
3. When the primary server comes back online, the backup is automatically deactivated
4. All events are logged for reference and diagnostics

---

## 📋 Menu and Functionality

The program offers a comprehensive menu interface:

1. **Installation**: Guided setup of the backup server
2. **Uninstallation**: Service removal with restoration options
3. **Status check**: Monitoring of system conditions
4. **View logs**: Access to failover event records
5. **System test**: Simulation of interruptions to verify operation

---

## 🔄 Installation Process

The installation is fully guided and includes:

1. **Automatic detection** of hardware and network settings
2. **Customizable configuration** of all key parameters
3. **Backup** of original configurations
4. **Installation of necessary** packages
5. **Script creation** and systemd services
6. **Activation** and system verification

---

## 📈 Monitoring and Logging

```
2025-05-14 11:44:22 - Primary router unreachable. Starting backup DHCP server...
2025-05-14 11:44:24 - Backup DHCP server successfully started
2025-05-14 11:48:14 - Primary router back online. Stopping backup DHCP server...
2025-05-14 11:48:14 - Backup DHCP server successfully stopped
```

The system tracks all events in `/var/log/dhcp-failover.log`:
- Detected interruptions
- Activations/deactivations of the backup server
- Errors or anomalous situations
- Connection restorations

---

## 🔬 Testing and Simulation

The testing functionality allows you to verify the system without real interruptions:

```bash
# Temporarily block communication with the primary server
sudo iptables -A OUTPUT -d 192.168.1.1 -j DROP

# Wait 30-45 seconds to see activation

# Restore communication
sudo iptables -D OUTPUT -d 192.168.1.1 -j DROP
```

---

## 🔒 Backup and Restoration

The system maintains complete backups in `/var/lib/dhcp-failover-backup/`:

- Original DHCP configurations
- Service status before installation
- Complete configuration parameters
- Timestamp of each installation

During uninstallation, you can easily restore any previous configuration.

---

## 📁 Main Files

- **`/usr/local/bin/dhcp-failover.sh`**: Main monitoring script
- **`/etc/systemd/system/dhcp-failover.service`**: Systemd service definition
- **`/etc/dhcp/dhcpd.conf`**: DHCP server configuration
- **`/var/log/dhcp-failover.log`**: Event log file
- **`/var/lib/dhcp-failover-backup/`**: Backup directory

---

## 🛡️ Security Considerations

- The backup server is active only when necessary
- MAC address-based configuration to prevent spoofing
- Customizable check intervals
- Works exclusively on the local network

---

## 📊 Ideal Use Cases

- **Small businesses** without redundant IT infrastructure
- **Home offices** requiring constant connectivity
- **Laboratories** or classrooms with high availability requirements
- **Home networks** for enthusiasts who want maximum reliability

---

## 🔧 Useful Commands

```bash
# Check failover service status
sudo systemctl status dhcp-failover.service

# Monitor logs in real-time
sudo tail -f /var/log/dhcp-failover.log

# Restart service after changes
sudo systemctl restart dhcp-failover.service

# Manual test of primary server status
ping -c 3 192.168.1.1
```

---

## 🚀 Getting Started

Start the program with:

```bash
sudo bash go-dhcp-failover-manager.sh
```

Follow the guided procedure and in a few minutes, you'll have a DHCP system with automatic failover!

---

## 📚 Authors and Contributions

This project was developed as a solution to ensure DHCP service continuity in environments where network availability is critical.

For suggestions or reports, use the Issues section of the repository.



#ITALIANO

# DHCP Failover Manager
## Sistema di Backup Automatico per Server DHCP

## Panoramica

Il **DHCP Failover Manager** è una soluzione bash progettata per ambienti Linux Debian che fornisce un server DHCP di backup automatico. Quando il server DHCP principale (tipicamente il router) diventa irraggiungibile, il sistema attiva autonomamente un server DHCP secondario, garantendo continuità di servizio nella rete locale.

---

## 🌟 Caratteristiche principali

- **Monitoraggio automatico** del server DHCP principale
- **Attivazione/disattivazione dinamica** del server di backup
- **Configurazione personalizzabile** di range IP, DNS e altre impostazioni
- **Logging dettagliato** di tutti gli eventi di failover
- **Backup completi** delle configurazioni originali
- **Interfaccia utente intuitiva** per gestione e configurazione
- **Funzionalità di test** integrate

---

## 🛠️ Requisiti di sistema

- **OS:** Debian 12 o distribuzioni basate su Debian
- **Privilegi:** Accesso root
- **Pacchetti:** isc-dhcp-server (installato automaticamente)
- **Rete:** IP statico sul server di backup

---

## ⚙️ Architettura del sistema

```
                   ┌───────────────┐
                   │ Server DHCP   │
                   │  Principale   │◄────┐
                   │  (Router)     │     │
                   └───────────────┘     │ Ping
                           ▲             │ periodico
                           │             │
                           ×             │
                     Interruzione        │
                           │             │
                           ▼             │
┌───────────────────────────────────────┐│
│ Server Debian                         ││
│                                       ││
│  ┌─────────────────────────────────┐  ││
│  │ DHCP Failover Service           │  ││
│  │                                 │  ││
│  │  ┌─────────────┐ ┌───────────┐ │  ││
│  │  │  Monitor    │ │ isc-dhcp- │ │  ││
│  │  │  Script     │ │  server   │ │  ││
│  │  └─────────────┘ └───────────┘ │  ││
│  └─────────────────────────────────┘  ││
└───────────────────────────────────────┘┘
```

---

## 🚀 Come funziona

1. Uno script bash eseguito come servizio systemd monitora continuamente il server DHCP principale tramite ping
2. Se il server principale non risponde, il sistema attiva il server DHCP di backup
3. Quando il server principale torna online, il backup viene automaticamente disattivato
4. Tutti gli eventi vengono registrati per riferimento e diagnostica

---

## 📋 Menù e funzionalità

Il programma offre un'interfaccia a menu completa:

1. **Installazione**: Configurazione guidata del server di backup
2. **Disinstallazione**: Rimozione del servizio con opzioni di ripristino
3. **Verifica stato**: Monitoraggio delle condizioni del sistema
4. **Visualizza log**: Accesso ai registri degli eventi di failover
5. **Test sistema**: Simulazione di interruzioni per verificare il funzionamento

---

## 🔄 Processo di installazione


L'installazione è completamente guidata e include:

1. **Rilevamento automatico** dell'hardware e delle impostazioni di rete
2. **Configurazione personalizzabile** di tutti i parametri principali
3. **Backup** delle configurazioni originali
4. **Installazione pacchetti** necessari
5. **Creazione script** e servizi systemd
6. **Attivazione** e verifica del sistema

---

## 📈 Monitoraggio e logging

```
2025-05-14 11:44:22 - Router principale non raggiungibile. Avvio del server DHCP di backup...
2025-05-14 11:44:24 - Server DHCP di backup avviato con successo
2025-05-14 11:48:14 - Router principale tornato online. Arresto del server DHCP di backup...
2025-05-14 11:48:14 - Server DHCP di backup arrestato con successo
```

Il sistema tiene traccia di tutti gli eventi in `/var/log/dhcp-failover.log`:
- Interruzioni rilevate
- Attivazioni/disattivazioni del server backup
- Errori o situazioni anomale
- Ripristini di connessione

---

## 🔬 Testing e simulazione

La funzionalità di test permette di verificare il sistema senza interruzioni reali:

```bash
# Blocca temporaneamente la comunicazione col server principale
sudo iptables -A OUTPUT -d 192.168.1.1 -j DROP

# Attendi 30-45 secondi per vedere l'attivazione

# Ripristina la comunicazione
sudo iptables -D OUTPUT -d 192.168.1.1 -j DROP
```

---

## 🔒 Backup e ripristino

Il sistema mantiene backup completi in `/var/lib/dhcp-failover-backup/`:

- Configurazioni DHCP originali
- Stato dei servizi prima dell'installazione
- Parametri completi della configurazione
- Timestamp di ogni installazione

Durante la disinstallazione è possibile ripristinare facilmente qualsiasi configurazione precedente.

---

## 📁 File principali

- **`/usr/local/bin/dhcp-failover.sh`**: Script principale di monitoraggio
- **`/etc/systemd/system/dhcp-failover.service`**: Definizione del servizio systemd
- **`/etc/dhcp/dhcpd.conf`**: Configurazione del server DHCP
- **`/var/log/dhcp-failover.log`**: File di log degli eventi
- **`/var/lib/dhcp-failover-backup/`**: Directory dei backup

---

## 🛡️ Considerazioni sulla sicurezza

- Il server di backup è attivo solo quando necessario
- Configurazione basata su MAC address per prevenire spoofing
- Intervalli di controllo personalizzabili
- Funziona esclusivamente nella rete locale

---

## 📊 Casi d'uso ideali

- **Piccole aziende** senza infrastruttura IT ridondante
- **Uffici domestici** con necessità di connettività costante
- **Laboratori** o aule didattiche con requisiti di alta disponibilità
- **Reti domestiche** di appassionati che vogliono massima affidabilità

---

## 🔧 Comandi utili

```bash
# Verifica stato del servizio di failover
sudo systemctl status dhcp-failover.service

# Controlla log in tempo reale
sudo tail -f /var/log/dhcp-failover.log

# Riavvia il servizio dopo modifiche
sudo systemctl restart dhcp-failover.service

# Test manuale dello stato del server principale
ping -c 3 192.168.1.1
```

---

## 🚀 Come iniziare

Avvia il programma con:

```bash
sudo bash go-dhcp-failover-manager.sh
```

Segui la procedura guidata e in pochi minuti avrai un sistema DHCP con failover automatico!

---

## 📚 Autori e contributi

Questo progetto è stato sviluppato come soluzione per garantire la continuità del servizio DHCP in ambienti dove la disponibilità di rete è critica.

Per suggerimenti o segnalazioni, utilizza la sezione Issues del repository.
