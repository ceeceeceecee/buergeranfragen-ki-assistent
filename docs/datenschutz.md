# Datenschutz-Erklärung

## Bürgeranfragen-KI-Assistent

### Überblick

Der Bürgeranfragen-KI-Assistent verarbeitet personenbezogene Daten ausschließlich lokal auf dem eigenen Server. Es werden keine Cloud-Dienste oder externen APIs verwendet.

### Datenverarbeitung

| Komponente | Daten | Verarbeitungsort |
|-----------|-------|-----------------|
| Ollama | E-Mail-Inhalte zur Klassifizierung | Lokaler Server |
| PostgreSQL | Audit-Log aller Vorgänge | Lokaler Server |
| n8n | Workflow-Daten | Lokaler Server |

### Keine Datenabflüsse

- **Ollama** läuft als lokaler Docker-Container — keine Anbindung an externe KI-Dienste
- **Keine Telemetrie** — keine Nutzungsdaten werden gesendet
- **Keine Cloud-Speicherung** — alle Daten bleiben auf dem Server

### Audit-Protokollierung

Jede KI-Verarbeitung wird in PostgreSQL protokolliert:
- Eingehende E-Mail (Absender, Betreff, Datum)
- KI-Klassifizierungsergebnis
- Generierte Antwort
- Zeitstempel der Verarbeitung

### Löschkonzept

Audit-Log-Einträge können automatisch gelöscht werden:

```sql
-- Einträge älter als 12 Monate löschen
DELETE FROM audit_log WHERE created_at < NOW() - INTERVAL '12 months';
```

Empfohlen: Cronjob für automatische Bereinigung einrichten.

### Technische Sicherheit

- **Verschlüsselte Verbindungen**: TLS für IMAP/SMTP
- **Passwort-Schutz**: .env-Datei mit eingeschränkten Berechtigungen (chmod 600)
- **Netzwerk-Isolation**: Docker-Netzwerk trennt Services voneinander
- **Keine Root-Rechte**: Container laufen als Nicht-Root-Benutzer

### Verantwortlichkeit

Der Betreiber des Systems ist für die DSGVO-konforme Nutzung verantwortlich:
- Datenschutzbeauftragten informieren
- Verfahrensverzeichnis führen
- Betroffenenrechte gewährleisten (Auskunft, Löschung, Berichtigung)
- technische und organisatorische Maßnahmen dokumentieren

### Kontakt

Bei Fragen zum Datenschutz wenden Sie sich an den Betreiber der jeweiligen Installation.
