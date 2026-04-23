# Setup-Guide – Bürgeranfragen-KI-Assistent

## 📋 Voraussetzungen

- Docker Engine 20.10+ und Docker Compose v2+
- Mindestens 4 GB RAM (8 GB empfohlen)
- 20 GB freier Festplattenplatz
- E-Mail-Postfach mit IMAP/SMTP-Zugang
- OpenAI API-Key oder lokaler Ollama-Server

## 🔒 Sicherheitscheckliste

Bevor Sie mit der Installation beginnen, stellen Sie sicher:

- [ ] Docker-Engine ist auf dem aktuellen Stand (`docker version`)
- [ ] Firewall blockiert eingehende Verbindungen auf Port 5678 (n8n)
- [ ] Reverse Proxy (nginx/traefik) ist für HTTPS konfiguriert
- [ ] Starke Passwörter für Datenbank und n8n vergeben
- [ ] E-Mail-Zugangsdaten sicher gespeichert
- [ ] API-Keys sind nicht im Quellcode enthalten (nur in .env)
- [ ] Backup-Strategie für PostgreSQL ist eingerichtet
- [ ] Server-Zertifikate sind gültig (TLS 1.3)
- [ ] Datenschutzbeauftragter wurde informiert
- [ ] TOMs (technische und organisatorische Maßnahmen) dokumentiert

## 🚀 Installation

### 1. Repository klonen

```bash
git clone https://github.com/ceeceeceecee/buergeranfragen-ki-assistent.git
cd buergeranfragen-ki-assistent
```

### 2. Umgebungsvariablen konfigurieren

```bash
cp .env.example .env
nano .env
```

**Wichtige Variablen:**
- `IMAP_*` – Zugang zum Bürgeranfragen-Postfach
- `SMTP_*` – Versand von Erstantworten
- `OPENAI_API_KEY` – oder `OLLAMA_*` für lokale KI
- `POSTGRES_PASSWORD` – Starkes Passwort vergeben!

### 3. Docker Compose starten

```bash
docker compose up -d
```

### 4. Datenbank-Schema importieren

```bash
docker exec -i buergeranfragen-postgres \
  psql -U audit_user -d buergeranfragen_audit < audit/log_schema.sql
```

### 5. n8n konfigurieren

1. Browser öffnen: `http://localhost:5678`
2. Anmelden mit `.env`-Zugangsdaten
3. Workflow importieren: `workflow/buergeranfragen-assistent.json`
4. Credentials konfigurieren:
   - IMAP (E-Mail-Postfach)
   - SMTP (Erstantwort-Versand)
   - OpenAI API oder Ollama
   - PostgreSQL (Audit-Log)

### 6. Abteilungen konfigurieren

```bash
cp config/abteilungen.example.yaml config/abteilungen.yaml
nano config/abteilungen.yaml
```

Passen Sie E-Mail-Adressen und Abteilungsnamen an Ihre Kommune an.

## 🧪 Pilotbetrieb-Empfehlung

### Phase 1: Testbetrieb (2 Wochen)
- Nur internes Postfach verwenden
- Alle Antworten manuell prüfen
- Keine automatischen Erstantworten senden
- KI-Klassifizierung validieren

### Phase 2: Pilot (4 Wochen)
- Eingeschränkte Bürgeranfragen
- Automatische Erstantwort aktiv
- Sachbearbeiter Feedback sammeln
- Kategorien und Vorlagen optimieren

### Phase 3: Produktivbetrieb
- Vollständige Aktivierung
- Monitoring und Auswertung
- Regelmäßige Überprüfung der Audit-Logs

## 🔄 Backup & Wiederherstellung

```bash
# Backup erstellen
docker exec buergeranfragen-postgres \
  pg_dump -U audit_user buergeranfragen_audit > backup_$(date +%Y%m%d).sql

# Wiederherstellung
docker exec -i buergeranfragen-postgres \
  psql -U audit_user -d buergeranfragen_audit < backup_YYYYMMDD.sql
```

## 📊 Monitoring

### Healthcheck

```bash
# n8n Status
curl -s http://localhost:5678/healthz

# PostgreSQL Status
docker exec buergeranfragen-postgres pg_isready

# Audit-Log Statistik
docker exec buergeranfragen-postgres \
  psql -U audit_user -d buergeranfragen_audit \
  -c "SELECT kategorie, COUNT(*), AVG(dauer_sekunden) FROM audit_log GROUP BY kategorie;"
```

### Logs anzeigen

```bash
# n8n Logs
docker logs -f buergeranfragen-n8n

# PostgreSQL Logs
docker logs -f buergeranfragen-postgres
```

## ⚠️ Fehlerbehebung

| Problem | Lösung |
|---------|--------|
| n8n startet nicht | Logs prüfen: `docker logs buergeranfragen-n8n` |
| IMAP-Verbindung fehlgeschlagen | SSL/TLS prüfen, Port 993 |
| KI gibt keine JSON-Antwort | Prompt in n8n prüfen, Temperatur reduzieren |
| Audit-Log leer | PostgreSQL-Verbindung prüfen, Schema importieren |
| Erstantwort nicht versendet | SMTP-Credentials prüfen |
