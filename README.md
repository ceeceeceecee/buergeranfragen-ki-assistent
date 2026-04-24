# Bürgeranfragen-KI-Assistent

![DSGVO-konform](https://img.shields.io/badge/DSGVO-konform-brightgreen)
![Self-Hosted](https://img.shields.io/badge/Self--Hosted-100%25-blue)
![Ollama](https://img.shields.io/badge/KI-Ollama-orange)
![n8n](https://img.shields.io/badge/Workflow-n8n-ff6d5a)
![MIT](https://img.shields.io/badge/Lizenz-MIT-green)

**DSGVO-konforme KI-Bearbeitung von Bürgeranfragen** — komplett self-hosted, keine Cloud-APIs, keine Datenabflüsse.

## Was ist das?

Der Bürgeranfragen-KI-Assistent verarbeitet eingehende Bürger-E-Mails automatisch:
- **Klassifizierung** der Anfrage nach Kategorie (Baubehörde, Sozialamt, etc.)
- **Erstellung** einer professionellen Erstantwort
- **Audit-Protokollierung** jedes Vorgangs in PostgreSQL
- **Weiterleitung** an die zuständige Abteilung

Alle KI-Funktionen laufen über **Ollama** auf dem eigenen Server — keine Daten verlassen das System.

## Ein-Kommando-Installation

```bash
curl -sSL https://raw.githubusercontent.com/ceeceeceecee/buergeranfragen-ki-assistent/main/setup.sh | bash
```

Das interaktive Setup-Script führt durch die komplette Installation:
1. Systemprüfung & Abhängigkeiten
2. Ollama + KI-Modell
3. Open WebUI (optional)
4. n8n Workflow-Engine
5. E-Mail-Konfiguration
6. Workflow-Import
7. Auto-Start
8. Health-Check

**Alternativ:** Repo klonen und Setup-Script ausführen:
```bash
git clone https://github.com/ceeceeceecee/buergeranfragen-ki-assistent.git
cd buergeranfragen-ki-assistent
chmod +x setup.sh
./setup.sh
```

### Unattended-Installation
```bash
# .env anpassen, dann:
./setup.sh --unattended
```

### Nur Systemprüfung
```bash
./setup.sh --check
```

## 🚀 Schnellstart

### Voraussetzungen

| Komponente | Version | Zweck |
|---|---|---|
| Ollama | neueste | Lokale KI-Verarbeitung |
| n8n | neueste | Workflow-Engine |
| PostgreSQL | 14+ | Audit-Protokollierung |
| IMAP-Postfach | — | E-Mail-Empfang |
| Docker (optional) | 20.10+ | Container-Deployment |

### Installation

```bash
git clone https://github.com/ceeceeceecee/buergeranfragen-ki-assistent.git
cd buergeranfragen-ki-assistent

# Ein-Kommando-Installation
chmod +x setup.sh
./setup.sh

# Oder unattended:
cp .env.example .env && ./setup.sh --unattended
```

### Erste Schritte

1. **Setup abschließen** — Das interaktive Script führt durch Ollama, n8n, E-Mail-Konfiguration
2. **KI-Modell herunterladen** — Setup lädt empfohlenes Modell automatisch
3. **Workflow importieren** — n8n Workflows werden automatisch importiert
4. **Test-E-Mail** senden und KI-Klassifizierung prüfen

---

## Features

| Feature | Beschreibung |
|---------|-------------|
| E-Mail-Empfang | IMAP-basiert, neue Nachrichten automatisch abrufen |
| KI-Klassifizierung | Lokale KI (Ollama) ordnet Anfragen zu |
| Erstantwort | Automatische höfliche Erstantwort mit DSGVO-Hinweis |
| Audit-Log | Jeder Vorgang wird in PostgreSQL protokolliert |
| Open WebUI | Web-Oberfläche zum Testen der KI (optional) |
| Self-Hosted | 100% lokal, kein Cloud-Service |
| DSGVO-konform | Keine Datenabflüsse, vollständige Protokollierung |

## Architektur

```
  Bürger-E-Mail
       |
       v
  +----------+     +----------+     +-----------+
  | IMAP     |---->| n8n      |---->| Ollama    |
  | Postfach |     | Workflow |<----| (lokal)   |
  +----------+     +----+-----+     +-----------+
                        |                |
                   +----v-----+    +----v-----+
                   | Postgres |    | KI-Modell|
                   | Audit-Log|    | (llama)  |
                   +----------+    +----------+
                        |
                   +----v-----+
                   | SMTP     |
                   | Antwort  |
                   +----------+
```

## KI-Modelle

Empfohlene Modelle (über Ollama):

| Modell | Größe | RAM | Qualität |
|--------|-------|-----|----------|
| llama3.1 (8B) | 4.7 GB | 8 GB | Empfohlen |
| mistral (7B) | 4.1 GB | 8 GB | Schnell |
| llama3.1 (70B) | 40 GB | 48 GB | Hochwertig |

## 📸 Screenshots

### Dashboard — Übersicht aller Bürgeranfragen
![Dashboard](screenshots/dashboard.png)

### Klassifizierung — Automatische KI-Kategorisierung
![Klassifizierung](screenshots/klassifizierung-beispiel.png)

### Workflow-Diagramm — Verarbeitungspipeline
![Workflow](screenshots/workflow-diagramm.png)

### Audit-Log — Protokollierte Bearbeitungsschritte
![Audit-Log](screenshots/audit-log.png)

## DSGVO

Dieses Projekt ist von Grund auf für den Einsatz in öffentlichen Verwaltungen konzipiert:

- **Keine Cloud-APIs**: Ollama läuft vollständig auf dem eigenen Server
- **Keine Datenübertragung**: Bürgerdaten verlassen das System nie
- **Vollständige Protokollierung**: Jede KI-Antwort wird in PostgreSQL auditiert
- **Löschkonzept**: Automatisches Löschen alter Audit-Einträge konfigurierbar
- **Verschlüsselung**: TLS für IMAP/SMTP, PostgreSQL-Verbindung verschlüsselt

Siehe auch: [Datenschutzerklärung](docs/datenschutz.md)

## Verwaltungs-Use-Cases

- **Stadtverwaltung**: Bürgeranfragen, Bescheinigungen, Meldewesen
- **Landratsamt**: Bauanträge, Genehmigungen, Förderungen
- **Behörde**: Beschwerden, Anträge, Auskünfte

## Systemanforderungen

- Docker & Docker Compose
- 4+ CPU-Kerne
- 8+ GB RAM (16 GB empfohlen)
- 20 GB freier Speicherplatz

## Entwickeln

```bash
# GPU-Support aktivieren
docker compose --profile gpu up -d

# Open WebUI aktivieren
docker compose --profile webui up -d

# Logs anzeigen
docker compose logs -f n8n
```

## Lizenz

MIT — siehe [LICENSE](LICENSE)

## Autor

Entwickelt für DSGVO-konforme Bürgerkommunikation.
