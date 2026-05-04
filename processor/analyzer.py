"""Ollama KI-Analyse fuer Buergeranfragen."""
import json, requests

class AnfragenAnalyzer:
    def __init__(self, url=None, model="llama3.1:8b", temp=0.2, tokens=4096):
        self.url=url.rstrip("/"); self.model=model; self.temp=temp; self.tokens=tokens
    def is_available(self):
        try: return requests.get(f"{self.url}/api/tags",timeout=3).status_code==200
        except: return False
    def analyze(self, anfrage):
        prompt=f"""Du bist ein Sachbearbeiter in einer deutschen Stadtverwaltung. Beantworte die folgende Buergeranfrage professionell und hilfsbereit.

Betreff: {anfrage.get('betreff','')}
Kategorie: {anfrage.get('kategorie','')}
Prioritaet: {anfrage.get('prioritaet','')}
Absender: {anfrage.get('absender','')}
Nachricht: {anfrage.get('nachricht','')}

Gib deine Antwort als JSON zurueck:
{{"antwort": "Deine professionelle Antwort an den Buerger", "kategorie_vorschlag": "passendere Kategorie falls noetig", "weiterleitung_an": "zuständige Abteilung", "dringlichkeit": "hoch/mittel/niedrig"}}"""
        if self.is_available():
            try:
                r=requests.post(f"{self.url}/api/generate",json={"model":self.model,"prompt":prompt,"stream":False,"options":{"temperature":self.temp,"num_predict":self.tokens}},timeout=120)
                text=r.json().get("response","")
                start=text.find("{"); end=text.rfind("}")+1
                if start>=0 and end>start: return json.loads(text[start:end])
            except: pass
        # Demo
        kat_map={"Muell/Abfall":"Abfallwirtschaftsbetrieb","Strassen/Verkehr":"Tiefbauamt","Anmeldung/Ausweis":"Buergeramt","Beschwerde":"Ordnungsamt","Auskunft":"Zentrale Auskunft"}
        return {"antwort":f"Sehr geehrte/r {anfrage.get('absender','Buerger/in')},\n\nvielen Dank fuer Ihre Nachricht zum Thema \"{anfrage.get('betreff','')}\". Wir haben Ihre Anfrage entgegengenommen und werden sie umgehend bearbeiten.\n\nIhre Anfrage wurde an das {kat_map.get(anfrage.get('kategorie',''),'zuständige Amt')} weitergeleitet. Sie erhalten innerhalb von 5 Werktagen eine Antwort.\n\nMit freundlichen Gruessen\nStadtverwaltung Musterhausen","kategorie_vorschlag":anfrage.get('kategorie',''),"weiterleitung_an":kat_map.get(anfrage.get('kategorie',''),"Zentrale Auskunft"),"dringlichkeit":anfrage.get('prioritaet','mittel'),"demo_mode":True}
