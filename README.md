# Buergeranfragen Ki Assistent

<p align="center">
<img src="https://raw.githubusercontent.com/ceeceeceecee/ai-document-analyzer/main/docs/coletrading-banner.svg" alt="ColeTrading" width="600">
</p>

![DSGVO](https://img.shields.io/badge/DSGVO-Konform-brightgreen) ![Self-Hosted](https://img.shields.io/badge/Self-Hosted-100%-blue) ![Ollama](https://img.shields.io/badge/Ollama-KI-orange?logo=ollama) ![n8n](https://img.shields.io/badge/n8n-Workflow-ff6d5a?logo=n8n) ![License](https://img.shields.io/badge/License-MIT-green)

> KI-gestützte Bürgeranfragen-Beantwortung für Kommunen (DSGVO-konform)

## Overview

Automatische Klassifizierung und Beantwortung von Bürgeranfragen. n8n-Workflow mit PostgreSQL-Datenbank, Ollama-KI und E-Mail-Integration. Komplett self-hosted und DSGVO-konform.

## Features

- Automatische Anfragen-Klassifizierung
- KI-gestützte Antwort-Generierung
- PostgreSQL-Datenbank
- Audit-Log für Nachvollziehbarkeit
- E-Mail-Integration
- Konfigurierbare Antwort-Vorlagen

## Tech Stack

| Tech | Zweck |
|------|-------|
| n8n | Workflow-Orchestrierung |
| Ollama | Lokale KI |
| PostgreSQL | Datenbank |
| Python | Hilfsscripte |
| Docker Compose | Deployment |

## Quick Start

```bash
bash setup.sh
# oder: docker compose up -d
```

## Screenshots

**Dashboard mit Anfragenübersicht**

<img src="screenshots/dashboard.png" alt="Dashboard mit Anfragenübersicht" width="800">

**KI-Klassifizierung einer Anfrage**

<img src="screenshots/klassifizierung-beispiel.png" alt="KI-Klassifizierung einer Anfrage" width="800">

**Workflow-Architektur**

<img src="screenshots/workflow-diagramm.png" alt="Workflow-Architektur" width="800">

**Audit-Log für Nachvollziehbarkeit**

<img src="screenshots/audit-log.png" alt="Audit-Log für Nachvollziehbarkeit" width="800">

---

## Contributing

Beiträge sind willkommen! Bitte erstelle einen Issue oder Pull Request.

## License

MIT License — siehe [LICENSE](LICENSE).

<p align="center">
<a href="https://github.com/ceeceeceecee">ColeTrading</a> &bull; DSGVO-konform &bull; Self-Hosted &bull; Open Source
</p>