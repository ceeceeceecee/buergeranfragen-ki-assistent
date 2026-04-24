#!/usr/bin/env bash
# =============================================================================
# Bürgeranfragen-KI-Assistent — Interaktives Setup-Script
# DSGVO-konform, Self-Hosted, Ollama-basiert
# =============================================================================
set -euo pipefail

# -- Farben & Formatierung -----------------------------------------------------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m'

info()  { echo -e "  ${BLUE}i${NC} $*"; }
ok()    { echo -e "  ${GREEN}✓${NC} $*"; }
warn()  { echo -e "  ${YELLOW}!${NC} $*"; }
err()   { echo -e "  ${RED}✗${NC} $*" >&2; }
step()  { echo -e "\n${BOLD}[$1/$TOTAL_STEPS] $2${NC}"; }
header() {
  echo -e "\n${BOLD}========================================${NC}"
  echo -e "${BOLD}  Bürgeranfragen-KI-Assistent — Setup${NC}"
  echo -e "${BOLD}========================================${NC}"
}
footer() {
  echo -e "\n${BOLD}========================================${NC}"
  echo -e "${BOLD}  Installation abgeschlossen! ${GREEN}✓${NC}${BOLD}${NC}"
  echo -e "${BOLD}========================================${NC}"
}

ask() {
  local prompt="$1" default="${2:-}"
  if [[ -n "$default" ]]; then
    echo -ne "  ${prompt} [${default}]: "
  else
    echo -ne "  ${prompt}: "
  fi
  local reply
  read -r reply
  echo "${reply:-$default}"
}

ask_yes() {
  local prompt="$1" default="${2:-J}"
  local reply
  reply=$(ask "$prompt" "$default")
  [[ "$reply" =~ ^[JjYy]$ ]]
}

ask_password() {
  local prompt="$1"
  echo -ne "  ${prompt}: "
  local reply
  read -rs reply
  echo ""
  echo "$reply"
}

die() { err "$*"; exit 1; }

# -- Verzeichnis ---------------------------------------------------------------
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
readonly ENV_FILE="${SCRIPT_DIR}/.env"
readonly WORKFLOW_FILE="${SCRIPT_DIR}/workflow/buergeranfragen-assistent.json"
TOTAL_STEPS=8

# -- Unattended Mode -----------------------------------------------------------
UNATTENDED=false
CHECK_ONLY=false

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --unattended) UNATTENDED=true ;;
      --check) CHECK_ONLY=true ;;
      --help|-h)
        echo "Usage: $0 [--unattended] [--check]"
        echo ""
        echo "  --unattended  Automatische Installation (benötigt .env)"
        echo "  --check       Nur Systemprüfung, nichts installieren"
        echo "  --help        Diese Hilfe"
        exit 0
        ;;
      *) die "Unbekannte Option: $1" ;;
    esac
    shift
  done
}

# -- Systemerkennung -----------------------------------------------------------
detect_os() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS_ID="${ID}"
    OS_VERSION="${VERSION_ID}"
    OS_NAME="${PRETTY_NAME}"
  elif command -v yum &>/dev/null; then
    OS_ID="rhel"
    OS_NAME="RHEL/CentOS"
  else
    OS_ID="unknown"
    OS_NAME="Unbekannt"
  fi
  info "Betriebssystem: ${OS_NAME}"
}

# -- Paketmanager --------------------------------------------------------------
pkg_install() {
  local packages=("$@")
  case "$OS_ID" in
    ubuntu|debian)
      sudo apt-get update -qq
      sudo apt-get install -y -qq "${packages[@]}"
      ;;
    fedora)
      sudo dnf install -y "${packages[@]}"
      ;;
    rhel|centos|rocky|alma)
      sudo yum install -y "${packages[@]}"
      ;;
    *)
      die "Nicht unterstütztes Betriebssystem: ${OS_NAME}"
      ;;
  esac
}

# -- Abhängigkeiten prüfen -----------------------------------------------------
check_command() {
  if command -v "$1" &>/dev/null; then
    local version
    version=$("$1" --version 2>/dev/null | head -1 || echo "")
    ok "$1 ${version} gefunden"
    return 0
  else
    warn "$1 nicht gefunden"
    return 1
  fi
}

check_system() {
  step 1 "Systemprüfung..."
  detect_os

  local missing=()
  check_command docker || missing+=(docker)
  check_command docker || {
    # Docker Compose Check
    if docker compose version &>/dev/null; then
      ok "Docker Compose v2 (Plugin) gefunden"
    elif docker-compose --version &>/dev/null; then
      ok "Docker Compose (Standalone) gefunden"
    else
      missing+=(docker-compose)
    fi
  } || true

  check_command curl || missing+=(curl)
  check_command git || missing+=(git)

  # Systemressourcen
  local cpus
  cpus=$(nproc 2>/dev/null || echo "?")
  local ram_gb
  if [[ -f /proc/meminfo ]]; then
    ram_gb=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024 / 1024 ))
  else
    ram_gb="?"
  fi
  ok "${cpus} CPU-Kerne, ${ram_gb} GB RAM erkannt"

  if [[ ${#missing[@]} -gt 0 ]]; then
    if $CHECK_ONLY; then
      err "Fehlende Pakete: ${missing[*]}"
      exit 1
    fi
    if $UNATTENDED; then
      warn "Unattended-Modus: Installiere fehlende Pakete..."
      pkg_install "${missing[@]}"
    elif ask_yes "Fehlende Pakete installieren? (${missing[*]})" "J"; then
      pkg_install "${missing[@]}"
    else
      die "Abhängigkeiten fehlen. Bitte installieren: ${missing[*]}"
    fi
  fi
}

# -- Docker-Gruppe -------------------------------------------------------------
ensure_docker_group() {
  if groups | grep -q docker; then
    return 0
  fi
  warn "Benutzer nicht in Docker-Gruppe"
  if ! $UNATTENDED; then
    if ask_yes "Benutzer zur Docker-Gruppe hinzufügen? (sudo erforderlich)" "J"; then
      sudo usermod -aG docker "$(whoami)"
      warn "Neue Gruppe wird beim nächsten Login wirksam."
    fi
  fi
}

# -- Env-Datei ----------------------------------------------------------------
load_env() {
  if [[ -f "$ENV_FILE" ]]; then
    set -a; source "$ENV_FILE"; set +a
  fi
}

write_env() {
  cat > "$ENV_FILE" <<ENVEOF
# ============================================
# Bürgeranfragen-KI-Assistent — Konfiguration
# Generiert am $(date -Iseconds)
# ============================================

# --- Ollama ---
OLLAMA_MODEL=${OLLAMA_MODEL:-llama3.1}
OLLAMA_HOST=${OLLAMA_HOST:-0.0.0.0}
OLLAMA_PORT=11434

# --- n8n ---
N8N_HOST=${N8N_HOST:-0.0.0.0}
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_BASIC_AUTH_ACTIVE=false
N8N_ENCRYPTION_KEY=$(openssl rand -hex 24)

# --- PostgreSQL ---
POSTGRES_DB=n8n
POSTGRES_USER=n8n
POSTGRES_PASSWORD=$(openssl rand -hex 16)
POSTGRES_PORT=5432

# --- Open WebUI ---
WEBUI_ENABLED=${WEBUI_ENABLED:-true}
WEBUI_PORT=3000

# --- E-Mail ---
IMAP_SERVER=${IMAP_SERVER:-}
IMAP_PORT=${IMAP_PORT:-993}
IMAP_USER=${IMAP_USER:-}
IMAP_PASSWORD=${IMAP_PASSWORD:-}
SMTP_SERVER=${SMTP_SERVER:-}
SMTP_PORT=${SMTP_PORT:-587}
SMTP_USER=${SMTP_USER:-}
SMTP_PASSWORD=${SMTP_PASSWORD:-}
EMAIL_FROM=${EMAIL_FROM:-}

# --- Antwort-Vorlagen ---
ANTWORT_VORLAGEN=/app/config/antwort-vorlagen.yaml
ABTEILUNGEN=/app/config/abteilungen.yaml
ENVEOF
  chmod 600 "$ENV_FILE"
  ok "Konfiguration in .env gespeichert"
}

# -- Ollama Setup --------------------------------------------------------------
setup_ollama() {
  step 2 "Ollama installieren..."

  local install_mode="${OLLAMA_INSTALL_MODE:-docker}"

  if $UNATTENDED; then
    install_mode="${OLLAMA_INSTALL_MODE:-docker}"
  else
    echo -e "  Möchten Sie Ollama als Docker-Container (1) oder nativ (2) installieren?"
    local choice
    choice=$(ask "Wahl" "1")
    case "$choice" in
      1) install_mode="docker" ;;
      2) install_mode="native" ;;
      *) install_mode="docker" ;;
    esac
  fi

  if [[ "$install_mode" == "native" ]]; then
    setup_ollama_native
  else
    # Ollama wird über docker-compose gestartet
    ok "Ollama als Docker-Container konfiguriert"
  fi

  # Modell wählen
  local model="${OLLAMA_MODEL:-}"
  if $UNATTENDED && [[ -n "$model" ]]; then
    ok "Modell aus .env: ${model}"
  else
    echo -e "\n  KI-Modell herunterladen:"
    echo -e "  ${BLUE}1)${NC} llama3.1 (8B) — Empfohlen, 8GB RAM"
    echo -e "  ${BLUE}2)${NC} llama3.1 (70B) — Hochwertig, 48GB RAM"
    echo -e "  ${BLUE}3)${NC} mistral (7B) — Schnell, 8GB RAM"
    echo -e "  ${BLUE}4)${NC} Eigenes Modell"
    local mchoice
    mchoice=$(ask "Wahl" "1")
    case "$mchoice" in
      1) model="llama3.1" ;;
      2) model="llama3.1:70b" ;;
      3) model="mistral" ;;
      4) model=$(ask "Modellname" "") ;;
      *) model="llama3.1" ;;
    esac
  fi

  OLLAMA_MODEL="$model"

  # Modell herunterladen
  info "Modell ${model} wird heruntergeladen..."
  if docker compose -f "$COMPOSE_FILE" exec -T ollama ollama pull "$model" 2>/dev/null; then
    ok "${model} heruntergeladen"
  elif curl -s --fail http://localhost:11434/api/pull -d "{\"name\":\"${model}\"}" | grep -q "success"; then
    ok "${model} heruntergeladen"
  else
    warn "Modell wird beim ersten Start heruntergeladen"
  fi
}

setup_ollama_native() {
  info "Ollama nativ installieren..."
  if command -v ollama &>/dev/null; then
    ok "Ollama bereits installiert"
    return
  fi
  curl -fsSL https://ollama.ai/install.sh | sh
  ok "Ollama nativ installiert"
}

# -- Open WebUI ----------------------------------------------------------------
setup_webui() {
  step 3 "Open WebUI installieren... (optional)"

  local enable_webui="${WEBUI_ENABLED:-true}"
  if ! $UNATTENDED; then
    if ask_yes "Open WebUI installieren?" "J"; then
      enable_webui=true
    else
      enable_webui=false
    fi
  fi

  WEBUI_ENABLED="$enable_webui"
  if [[ "$enable_webui" == "true" ]]; then
    ok "Open WebUI konfiguriert (wird mit docker-compose gestartet)"
  else
    info "Open WebUI übersprungen"
  fi
}

# -- n8n Setup -----------------------------------------------------------------
setup_n8n() {
  step 4 "n8n installieren..."
  ok "n8n konfiguriert (wird mit docker-compose gestartet)"
}

# -- E-Mail Konfiguration ------------------------------------------------------
setup_email() {
  step 5 "E-Mail-Konfiguration..."

  if $UNATTENDED && [[ -n "${IMAP_SERVER:-}" ]]; then
    ok "E-Mail aus .env geladen"
    return
  fi

  IMAP_SERVER=$(ask "IMAP-Server" "")
  IMAP_PORT=$(ask "IMAP-Port" "993")
  IMAP_USER=$(ask "IMAP-Benutzer" "")
  IMAP_PASSWORD=$(ask_password "IMAP-Passwort")
  SMTP_SERVER=$(ask "SMTP-Server" "")
  SMTP_PORT=$(ask "SMTP-Port" "587")
  SMTP_USER=$(ask "SMTP-Benutzer" "")
  SMTP_PASSWORD=$(ask_password "SMTP-Passwort")
  EMAIL_FROM=$(ask "Absender-Adresse" "$IMAP_USER")

  ok "E-Mail-Konfiguration gespeichert"
}

# -- Docker Compose starten ----------------------------------------------------
start_services() {
  info "Docker-Container werden gestartet..."
  
  # docker-compose.yml schreiben falls nötig
  if [[ ! -f "$COMPOSE_FILE" ]]; then
    err "docker-compose.yml nicht gefunden!"
    die "Bitte stellen Sie sicher, dass docker-compose.yml existiert."
  fi

  # Env schreiben
  write_env

  # Services starten
  cd "$SCRIPT_DIR"
  if ! docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d 2>&1; then
    die "Docker Compose fehlgeschlagen!"
  fi
  ok "Alle Container gestartet"
}

# -- Workflow importieren ------------------------------------------------------
import_workflow() {
  step 6 "Workflow importieren..."

  if [[ ! -f "$WORKFLOW_FILE" ]]; then
    warn "Workflow-Datei nicht gefunden: ${WORKFLOW_FILE}"
    return
  fi

  info "Warte auf n8n-Start (max. 60s)..."
  local retries=0
  while ! curl -sf http://localhost:5678/healthz &>/dev/null; do
    sleep 2
    ((retries++))
    if (( retries > 30 )); then
      warn "n8n nicht erreichbar, überspringe Workflow-Import"
      return
    fi
  done

  ok "n8n ist erreichbar"

  # Workflow via n8n API importieren
  local response
  response=$(curl -s -X POST http://localhost:5678/api/v1/workflows/import \
    -H "Content-Type: application/json" \
    -d @"$WORKFLOW_FILE" 2>/dev/null)

  if echo "$response" | grep -q '"id"'; then
    ok "Bürgeranfragen-Workflow in n8n importiert"
  else
    warn "Workflow-Import fehlgeschlagen (manuell in n8n importieren)"
  fi
}

# -- Systemd Service -----------------------------------------------------------
setup_systemd() {
  step 7 "systemd-Service erstellen..."

  local create_service=true
  if ! $UNATTENDED; then
    if ! ask_yes "Auto-Start einrichten?" "J"; then
      create_service=false
    fi
  fi

  if [[ "$create_service" != "true" ]]; then
    info "Systemd-Service übersprungen"
    return
  fi

  local service_file="/etc/systemd/system/buergeranfragen.service"
  local compose_path
  compose_path=$(readlink -f "$COMPOSE_FILE")

  sudo tee "$service_file" > /dev/null <<SERVICEEOF
[Unit]
Description=Bürgeranfragen-KI-Assistent (Docker Stack)
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${SCRIPT_DIR}
ExecStart=/usr/bin/docker compose -f ${compose_path} --env-file ${ENV_FILE} up -d
ExecStop=/usr/bin/docker compose -f ${compose_path} --env-file ${ENV_FILE} down
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
SERVICEEOF

  sudo systemctl daemon-reload
  sudo systemctl enable buergeranfragen.service
  ok "Systemd-Service erstellt und aktiviert"
}

# -- Firewall Check ------------------------------------------------------------
check_firewall() {
  local ports=(11434 5678 3000 5432)
  for port in "${ports[@]}"; do
    if command -v ufw &>/dev/null && sudo ufw status 2>/dev/null | grep -q "active"; then
      if sudo ufw status | grep -q "${port}"; then
        ok "Port ${port} in UFW erlaubt"
      else
        warn "Port ${port} nicht in UFW — ggf. 'sudo ufw allow ${port}'"
      fi
    elif command -v firewall-cmd &>/dev/null; then
      if sudo firewall-cmd --list-ports 2>/dev/null | grep -q "${port}"; then
        ok "Port ${port} in firewalld erlaubt"
      else
        warn "Port ${port} nicht in firewalld — ggf. 'sudo firewall-cmd --add-port=${port}/tcp --permanent'"
      fi
    fi
  done
}

# -- Health Check --------------------------------------------------------------
health_check() {
  step 8 "System-Check..."

  local failed=0

  # Ollama
  if curl -sf http://localhost:11434/api/tags &>/dev/null; then
    ok "Ollama: http://localhost:11434 — OK"
  else
    err "Ollama: http://localhost:11434 — FEHLER"
    ((failed++))
  fi

  # Open WebUI
  if [[ "${WEBUI_ENABLED:-true}" == "true" ]]; then
    if curl -sf http://localhost:3000 &>/dev/null; then
      ok "Open WebUI: http://localhost:3000 — OK"
    else
      err "Open WebUI: http://localhost:3000 — FEHLER"
      ((failed++))
    fi
  fi

  # n8n
  if curl -sf http://localhost:5678/healthz &>/dev/null; then
    ok "n8n: http://localhost:5678 — OK"
  else
    err "n8n: http://localhost:5678 — FEHLER"
    ((failed++))
  fi

  # PostgreSQL
  if docker compose -f "$COMPOSE_FILE" exec -T postgres pg_isready -U n8n &>/dev/null; then
    ok "PostgreSQL: Verbunden — OK"
  else
    err "PostgreSQL: Verbindung fehlgeschlagen"
    ((failed++))
  fi

  # Firewall
  check_firewall

  return $failed
}

# -- Abschluss -----------------------------------------------------------------
print_summary() {
  footer
  echo ""
  [[ "${WEBUI_ENABLED:-true}" == "true" ]] && ok "Open WebUI: http://localhost:3000"
  ok "n8n:        http://localhost:5678"
  ok "Ollama:     http://localhost:11434"
  echo ""
  echo -e "  ${BOLD}Nächste Schritte:${NC}"
  echo "  1. n8n öffnen und Workflow aktivieren"
  [[ -n "${EMAIL_FROM:-}" ]] && echo "  2. Test-E-Mail an ${EMAIL_FROM} senden"
  echo "  3. Audit-Log unter n8n → PostgreSQL prüfen"
  echo ""
}

# -- Check-Only Mode -----------------------------------------------------------
run_check_only() {
  header
  TOTAL_STEPS=1
  check_system
  echo ""
  info "Check-Modus abgeschlossen. Keine Änderungen vorgenommen."
}

# -- Unattended Mode -----------------------------------------------------------
run_unattended() {
  if [[ ! -f "$ENV_FILE" ]]; then
    die "Unattended-Modus benötigt .env Datei!"
  fi
  load_env
  info "Unattended-Modus — .env geladen"
}

# =============================================================================
# MAIN
# =============================================================================
main() {
  parse_args "$@"

  header

  if $CHECK_ONLY; then
    run_check_only
    exit 0
  fi

  if $UNATTENDED; then
    run_unattended
  fi

  ensure_docker_group
  check_system
  setup_ollama
  setup_webui
  setup_n8n
  setup_email
  start_services
  import_workflow
  setup_systemd
  health_check
  print_summary
}

main "$@"
