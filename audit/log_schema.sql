-- =====================================================
-- Audit-Log Schema für Bürgeranfragen-KI-Assistent
-- PostgreSQL Datenbankschema
-- =====================================================

-- Tabelle für Anfrage-Protokolle
CREATE TABLE IF NOT EXISTS audit_log (
    id              SERIAL PRIMARY KEY,
    anfrage_id      VARCHAR(36) NOT NULL UNIQUE,
    timestamp       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    absender_email  VARCHAR(255) NOT NULL,
    betreff         VARCHAR(500),
    kategorie       VARCHAR(100),
    prioritaet      VARCHAR(20) CHECK (prioritaet IN ('hoch', 'mittel', 'niedrig')),
    abteilung       VARCHAR(200),
    ziel_email      VARCHAR(255),
    erstantwort_id  VARCHAR(36),
    bearbeitet_von  VARCHAR(200),
    antwort_gesendet    BOOLEAN DEFAULT FALSE,
    dauer_sekunden      INTEGER,
    fehlermeldung       TEXT,
    rohdaten_geloescht  BOOLEAN DEFAULT FALSE,
    geloescht_am        TIMESTAMP WITH TIME ZONE
);

-- Index für häufige Abfragen
CREATE INDEX idx_audit_log_timestamp ON audit_log(timestamp);
CREATE INDEX idx_audit_log_kategorie ON audit_log(kategorie);
CREATE INDEX idx_audit_log_abteilung ON audit_log(abteilung);
CREATE INDEX idx_audit_log_prioritaet ON audit_log(prioritaet);
CREATE INDEX idx_audit_log_anfrage_id ON audit_log(anfrage_id);

-- Tabelle für automatische Löschung (Löschkonzept DSGVO)
CREATE TABLE IF NOT EXISTS loeschkonfiguration (
    id              SERIAL PRIMARY KEY,
    aufbewahrungs_tage INTEGER NOT NULL DEFAULT 90,
    letzter_lauf    TIMESTAMP WITH TIME ZONE,
    erstellt_am     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    aktualisiert_am TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Standard-Konfiguration: 90 Tage Aufbewahrung
INSERT INTO loeschkonfiguration (aufbewahrungs_tage) VALUES (90);

-- Funktion für automatische Bereinigung
CREATE OR REPLACE FUNCTION bereinige_audit_log()
RETURNS void AS $$
DECLARE
    aufbewahrungs_tage INTEGER;
BEGIN
    SELECT aufbewahrungs_tage INTO aufbewahrungs_tage
    FROM loeschkonfiguration
    ORDER BY id DESC LIMIT 1;

    -- Alte Einträge als gelöscht markieren
    UPDATE audit_log
    SET rohdaten_geloescht = TRUE,
        geloescht_am = NOW(),
        betreff = '[GELÖSCHT]',
        absender_email = '[GELÖSCHT]',
        fehlermeldung = NULL
    WHERE timestamp < NOW() - (aufbewahrungs_tage || ' days')::INTERVAL
      AND rohdaten_geloescht = FALSE;

    -- Einträge vollständig löschen (Doppelte Aufbewahrungsfrist)
    DELETE FROM audit_log
    WHERE timestamp < NOW() - (aufbewahrungs_tage * 2 || ' days')::INTERVAL;

    -- Letzten Lauf aktualisieren
    UPDATE loeschkonfiguration
    SET letzter_lauf = NOW()
    ORDER BY id DESC LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Statistik-Sicht
CREATE OR REPLACE VIEW v_anfragen_statistik AS
SELECT
    DATE_TRUNC('day', timestamp) AS datum,
    kategorie,
    prioritaet,
    COUNT(*) AS anzahl,
    AVG(dauer_sekunden) FILTER (WHERE dauer_sekunden IS NOT NULL) AS avg_dauer
FROM audit_log
WHERE rohdaten_geloescht = FALSE
GROUP BY DATE_TRUNC('day', timestamp), kategorie, prioritaet
ORDER BY datum DESC;
