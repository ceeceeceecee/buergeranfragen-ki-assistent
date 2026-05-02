"""SQLite Datenbank-Manager fuer Buergeranfragen-KI."""
import sqlite3, json, os
from datetime import datetime, timedelta
from pathlib import Path
import random

class DatabaseManager:
    def __init__(self, db_path=None):
        if db_path is None:
            base = Path(__file__).parent.parent / "data"
            base.mkdir(parents=True, exist_ok=True)
            db_path = str(base / "buergeranfragen.db")
        self.conn = sqlite3.connect(db_path, check_same_thread=False)
        self.conn.row_factory = sqlite3.Row
        self._create_tables()
        self._seed_demo_data()

    def _create_tables(self):
        self.conn.execute("""CREATE TABLE IF NOT EXISTS anfragen (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            referenz TEXT UNIQUE NOT NULL,
            betreff TEXT NOT NULL,
            kategorie TEXT NOT NULL,
            prioritaet TEXT DEFAULT 'mittel',
            absender TEXT,
            nachricht TEXT,
            status TEXT DEFAULT 'neu',
            antwort_json TEXT,
            erstellt_am TEXT NOT NULL,
            bearbeitet_am TEXT
        )""")
        self.conn.execute("""CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY, value TEXT NOT NULL
        )""")
        self.conn.commit()

    def _seed_demo_data(self):
        if self.conn.execute("SELECT COUNT(*) FROM anfragen").fetchone()[0] > 0:
            return
        kategorien = ["Muell/Abfall", "Strassen/Verkehr", "Anmeldung/Ausweis", "Beschwerde", "Auskunft"]
        prioritaeten = ["hoch", "mittel", "niedrig"]
        status_list = ["neu", "in_bearbeitung", "beantwortet", "geschlossen"]
        absender = ["Müller Schmidt", "Anna Weber", "Klaus Fischer", "Petra Koch", "Thomas Bauer",
                     "Maria Schulze", "Hans Hoffmann", "Ingrid Krüger", "Wolfgang Richter", "Sabine Klein"]
        anfragen_data = [
            ("BA-2026-0001", "Müllabfuhr verspätet", "Muell/Abfall", "mittel", "Müller Schmidt",
             "Die Müllabfuhr ist seit 3 Tagen nicht mehr da. Bitte umgehend klären.", "neu", -20),
            ("BA-2026-0002", "Straßenbeleuchtung defekt", "Strassen/Verkehr", "hoch", "Anna Weber",
             "Die Straßenlaterne an der Ecke Hauptstr./Birkenweg ist seit einer Woche defekt. Gefahrenquelle!", "beantwortet", -18),
            ("BA-2026-0003", "Personalausweis verlängern", "Anmeldung/Ausweis", "niedrig", "Klaus Fischer",
             "Möchte meinen Personalausweis verlängern. Welcher Termin ist möglich?", "geschlossen", -15),
            ("BA-2026-0004", "Lärmbelästigung Baustelle", "Beschwerde", "hoch", "Petra Koch",
             "Die Baustelle am Marktplatz macht seit 6 Uhr morgens Lärm. Das ist vor 7 Uhr nicht erlaubt!", "in_bearbeitung", -12),
            ("BA-2026-0005", "Geburtsurkunde anfordern", "Auskunft", "niedrig", "Thomas Bauer",
             "Brauche eine Geburtsurkunde für mein Kind. Wie kann ich diese beantragen?", "beantwortet", -10),
            ("BA-2026-0006", "Sperrmüll abholen", "Muell/Abfall", "niedrig", "Maria Schulze",
             "Brauche eine Sperrmüllabholung für nächste Woche. Adresse: Lindenstr. 15.", "neu", -8),
            ("BA-2026-0007", "Gehweg beschädigt", "Strassen/Verkehr", "hoch", "Hans Hoffmann",
             "Der Gehweg vor dem Haus Ahornstr. 22 ist stark beschädigt. Stolpergefahr für Senioren!", "neu", -7),
            ("BA-2026-0008", "Meldebescheinigung", "Anmeldung/Ausweis", "niedrig", "Ingrid Krüger",
             "Brauche eine aktuelle Meldebescheinigung für das Finanzamt.", "beantwortet", -6),
            ("BA-2026-0009", "Parkplatzverordnung", "Beschwerde", "mittel", "Wolfgang Richter",
             "Immer wieder werden Autos in zweiter Reihe geparkt. Bitte Überwachung verstärken.", "in_bearbeitung", -5),
            ("BA-2026-0010", "Bauvoranfrage", "Auskunft", "mittel", "Sabine Klein",
             "Plane einen Anbau an meinem Haus. Welche Unterlagen werden für eine Bauvoranfrage benötigt?", "neu", -4),
            ("BA-2026-0011", "Biotonne wird nicht geleert", "Muell/Abfall", "mittel", "Müller Schmidt",
             "Die Biotonne wurde trotz rechtzeitiger Bereitstellung nicht geleert.", "beantwortet", -3),
            ("BA-2026-0012", "Verkehrsberuhigung", "Strassen/Verkehr", "hoch", "Anna Weber",
             "In der Schulstraße fahren Autos viel zu schnell. Kinder auf dem Schulweg sind gefährdet!", "neu", -2),
            ("BA-2026-0013", "Reisepass beantragen", "Anmeldung/Ausweis", "niedrig", "Klaus Fischer",
             "Möchte einen Reisepass beantragen. Welche Dokumente muss ich mitbringen?", "geschlossen", -1),
            ("BA-2026-0014", "Wasserschaden melden", "Beschwerde", "hoch", "Petra Koch",
             "Im Treppenhaus unseres Mietshauses tropft Wasser aus der Decke. Vermutlich Rohrbruch!", "neu", 0),
            ("BA-2026-0015", "Öffnungszeiten Ausländerbehörde", "Auskunft", "niedrig", "Thomas Bauer",
             "Was sind die aktuellen Öffnungszeiten der Ausländerbehörde? Brauche einen Termin.", "beantwortet", -14),
            ("BA-2026-0016", "Gelber Sack nicht geliefert", "Muell/Abfall", "mittel", "Maria Schulze",
             "Die gelben Säcke für dieses Quartal wurden noch nicht zugestellt.", "neu", -1),
            ("BA-2026-0017", "Einbahnstraße prüfen", "Strassen/Verkehr", "mittel", "Hans Hoffmann",
             "Können Sie prüfen ob die Friedrichstraße als Einbahnstraße eingerichtet werden kann?", "in_bearbeitung", -9),
            ("BA-2026-0018", "Führungszeugnis", "Anmeldung/Ausweis", "niedrig", "Ingrid Krüger",
             "Wie beantrage ich ein erweitertes Führungszeugnis?", "beantwortet", -11),
            ("BA-2026-0019", "Spielplatz nicht sicher", "Beschwerde", "hoch", "Wolfgang Richter",
             "Der Spielplatz am Park hat einen defekten Zaun und kaputte Sitzgelegenheiten.", "neu", -2),
            ("BA-2026-0020", "Hundesteuer", "Auskunft", "niedrig", "Sabine Klein",
             "Wie hoch ist die Hundesteuer in Musterhausen und wie melde ich einen Hund an?", "geschlossen", -13),
        ]
        for ref, betr, kat, prio, abs, nachr, stat, days in anfragen_data:
            datum = (datetime.now() + timedelta(days=days)).strftime("%Y-%m-%d %H:%M")
            self.conn.execute("INSERT OR IGNORE INTO anfragen (referenz,betreff,kategorie,prioritaet,absender,nachricht,status,erstellt_am) VALUES (?,?,?,?,?,?,?,?,?)",
                (ref, betr, kat, prio, abs, nachr, stat, datum))
        defaults = {"ollama_url":"http://localhost:11434","ollama_model":"llama3.1:8b","sprache":"Deutsch",
                    "behoerde":"Stadtverwaltung Musterhausen","datenspeicherung":"Lokal","verschluesselung":"AES-256","protokollierung":"Aktiv"}
        for k,v in defaults.items():
            self.conn.execute("INSERT OR IGNORE INTO settings VALUES (?,?)",(k,v))
        self.conn.commit()

    def get_all_anfragen(self): return [dict(r) for r in self.conn.execute("SELECT * FROM anfragen ORDER BY erstellt_am DESC").fetchall()]
    def get_anfrage(self, ref): r=self.conn.execute("SELECT * FROM anfragen WHERE referenz=?",(ref,)).fetchone(); return dict(r) if r else None
    def create_anfrage(self, ref, betr, kat, prio, abs, nachr):
        d=datetime.now().strftime("%Y-%m-%d %H:%M")
        try: self.conn.execute("INSERT INTO anfragen VALUES (NULL,?,?,?,?,?,'neu',NULL,?,NULL)",(ref,betr,kat,prio,abs,nachr,d)); self.conn.commit(); return True
        except: return False
    def update_status(self, ref, status, antwort=None):
        d=datetime.now().strftime("%Y-%m-%d %H:%M")
        if antwort: self.conn.execute("UPDATE anfragen SET status=?,antwort_json=?,bearbeitet_am=? WHERE referenz=?",(status,json.dumps(antwort,ensure_ascii=False),d,ref))
        else: self.conn.execute("UPDATE anfragen SET status=?,bearbeitet_am=? WHERE referenz=?",(status,d,ref))
        self.conn.commit()
    def get_setting(self, k, d=""): r=self.conn.execute("SELECT value FROM settings WHERE key=?", (k,)).fetchone(); return r[0] if r else d
    def set_setting(self, k, v): self.conn.execute("INSERT OR REPLACE INTO settings VALUES (?,?)",(k,v)); self.conn.commit()
    def get_stats(self):
        t=self.conn.execute("SELECT COUNT(*) FROM anfragen").fetchone()[0]
        return {"total":t,"neu":self.conn.execute("SELECT COUNT(*) FROM anfragen WHERE status='neu'").fetchone()[0],
                "in_bearbeitung":self.conn.execute("SELECT COUNT(*) FROM anfragen WHERE status='in_bearbeitung'").fetchone()[0],
                "beantwortet":self.conn.execute("SELECT COUNT(*) FROM anfragen WHERE status='beantwortet'").fetchone()[0],
                "geschlossen":self.conn.execute("SELECT COUNT(*) FROM anfragen WHERE status='geschlossen'").fetchone()[0]}
    def get_category_counts(self):
        return dict(self.conn.execute("SELECT kategorie, COUNT(*) as c FROM anfragen GROUP BY kategorie").fetchall())
