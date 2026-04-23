# Datenschutz-Dokumentation – Bürgeranfragen-KI-Assistent

## ⚖️ Rechtsgrundlage

Die Verarbeitung personenbezogener Daten im Rahmen dieses Projekts erfolgt auf Grundlage von:

- **Art. 6 Abs. 1 lit. e DSGVO** – Ausführung einer Aufgabe im öffentlichen Interesse
- **Art. 6 Abs. 1 lit. c DSGVO** – Erfüllung einer rechtlichen Verpflichtung
- **§ 3 BDSG** – Verarbeitung personenbezogener Daten durch öffentliche Stellen

## 🔐 Verarbeitete Daten

| Datenkategorie | Beispiele | Speicherdauer |
|---------------|-----------|---------------|
| Absenderdaten | E-Mail-Adresse, Name | 90 Tage |
| Anfrageinhalt | Betreff, Text der Anfrage | 90 Tage |
| Metadaten | Datum, Uhrzeit, Kategorie | 90 Tage |
| Audit-Daten | Bearbeitungsschritte, Dauer | 180 Tage (aggregiert) |

## 🏗️ Datenfluss

```
E-Mail (IMAP) → n8n Container → KI-Modul → PostgreSQL Audit-Log
                     ↓                ↓
               SMTP Antwort      Abteilung
```

**Wichtig:** Keine Daten verlassen die eigene Infrastruktur. Bei Nutzung von OpenAI werden ausschließlich der Anfragetext (kein Absendername, keine E-Mail-Adresse) an die API gesendet.

## 🗑️ Löschkonzept

1. **Automatische Anonymisierung** nach 90 Tagen:
   - E-Mail-Adressen werden durch `[GELÖSCHT]` ersetzt
   - Betreffzeilen werden anonymisiert
   - Fehlermeldungen werden entfernt

2. **Automatische Löschung** nach 180 Tagen:
   - Vollständige Entfernung der Datensätze aus der Datenbank

3. **Manuelle Löschung** jederzeit möglich:
   - Über die Datenbank-Verwaltung
   - Auf Antrag des Bürgers (Art. 17 DSGVO)

## 🤖 KI-Verarbeitung

### Bei Cloud-KI (OpenAI)

- **Anonymisierung vor KI-Aufruf:** Absendername und E-Mail-Adresse werden vor der KI-Verarbeitung entfernt
- **Keine Speicherung durch OpenAI:** API-Privacy-Richtlinie aktiviert (zero data retention)
- **Minimaler Datentransfer:** Nur Anfragetext wird an die KI gesendet

### Bei lokaler KI (Ollama)

- **Kein Datenabfluss:** Alle Daten bleiben auf dem eigenen Server
- **Empfohlen für sensible Daten:** Ideal für Behörden mit strengen Datenschutzvorgaben

## 📋 Technische und organisatorische Maßnahmen (TOMs)

- **Verschlüsselung:** TLS 1.3 für alle Verbindungen
- **Zugangskontrolle:** Docker-Netzwerk ohne externen Zugriff
- **Protokollierung:** Vollständiger Audit-Trail
- **Verfügbarkeitskontrolle:** Docker Healthchecks, automatischer Neustart
- **Trennbarkeit:** Separate Container für Workflow-Engine und Datenbank

## 📝 Datenschutz-Folgenabschätzung

Für den produktiven Einsatz wird eine Datenschutz-Folgenabschätzung (Art. 35 DSGVO) empfohlen, insbesondere bei:

- Verarbeitung besonderer Kategorien personenbezogener Daten
- Einsatz von Cloud-KI-Diensten
- Verarbeitung großer Datenmengen (>10.000 Anfragen/Monat)

## 📞 Datenschutzbeauftragter

Der zuständige Datenschutzbeauftragte der Kommune ist vor Inbetriebnahme zu informieren. Die technische Dokumentation dieses Projekts dient als Grundlage für die Berichterstattung.
