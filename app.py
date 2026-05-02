"""Buergeranfragen-KI - Streamlit App"""
import streamlit as st, os, sys, json, plotly.express as px, pandas as pd
from datetime import datetime
from pathlib import Path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from database.db import DatabaseManager
from processor.analyzer import AnfragenAnalyzer

DB_PATH = os.getenv("DB_PATH", str(Path(__file__).parent / "data" / "buergeranfragen.db"))
db = DatabaseManager(DB_PATH)

st.set_page_config(page_title="Buergeranfragen-KI", page_icon="📨", layout="wide", initial_sidebar_state="expanded")
st.markdown("[data-testid='stSidebar']{background-color:#151e2e;} [data-testid='stSidebar'] *{color:#c8d6e5 !important;}", unsafe_allow_html=True)

if "analyzer" not in st.session_state:
    st.session_state.analyzer = AnfragenAnalyzer(db.get_setting("ollama_url","http://localhost:11434"), db.get_setting("ollama_model","llama3.1:8b"))

with st.sidebar:
    st.markdown("📨 **Buergeranfragen-KI**")
    st.caption("KI-gestuetzte Anfragebearbeitung")
    st.divider()
    stats = db.get_stats()
    st.markdown(f"Offen: **{stats['neu'] + stats['in_bearbeitung']}**")
    st.markdown(f"Beantwortet: **{stats['beantwortet']}**")
    st.divider()
    ok = st.session_state.analyzer.is_available()
    st.markdown("✅ Ollama verbunden" if ok else "⚠️ Demo-Modus")
    st.caption(f"Modell: {db.get_setting('ollama_model','llama3.1:8b')} (Ollama)")

page = st.sidebar.radio("Navigation", ["📊 Dashboard","📨 Anfragen","➕ Neue Anfrage","⚙️ Einstellungen"], label_visibility="collapsed")

if page == "📊 Dashboard":
    st.title("📊 Dashboard — Anfragenuebersicht")
    s = db.get_stats()
    c1,c2,c3,c4 = st.columns(4)
    c1.metric("🆕 Neu", s["neu"])
    c2.metric("⏳ In Bearbeitung", s["in_bearbeitung"])
    c3.metric("✅ Beantwortet", s["beantwortet"])
    c4.metric("📁 Gesamt", s["total"])
    st.divider()
    anfragen = db.get_all_anfragen()
    if anfragen:
        prio_map={"hoch":"🔴 Hoch","mittel":"🟡 Mittel","niedrig":"🟢 Niedrig"}
        stat_map={"neu":"🆕 Neu","in_bearbeitung":"⏳ Bearbeitung","beantwortet":"✅ Beantwortet","geschlossen":"✅ Geschlossen"}
        for a in anfragen:
            a["prio_display"]=prio_map.get(a["prioritaet"],a["prioritaet"])
            a["stat_display"]=stat_map.get(a["status"],a["status"])
        df=pd.DataFrame(anfragen)
        st.dataframe(df[["referenz","betreff","kategorie","prio_display","stat_display","erstellt_am"]],use_container_width=True,hide_index=True,height=450)
        cc=db.get_category_counts()
        if cc:
            cdf=pd.DataFrame(list(cc.items()),columns=["Kategorie","Anzahl"])
            fig=px.pie(cdf,values="Anzahl",names="Kategorie",title="Anfragen nach Kategorie")
            st.plotly_chart(fig,use_container_width=True)
    else:
        st.info("Keine Anfragen vorhanden.")

elif page == "📨 Anfragen":
    st.title("📨 Anfragen bearbeiten")
    anfragen = db.get_all_anfragen()
    if not anfragen: st.info("Keine Anfragen."); st.stop()
    kat_filter = st.selectbox("Kategorie", ["Alle"] + sorted(set(a["kategorie"] for a in anfragen)))
    stat_filter = st.selectbox("Status", ["Alle","neu","in_bearbeitung","beantwortet","geschlossen"])
    filtered = [a for a in anfragen if (kat_filter=="Alle" or a["kategorie"]==kat_filter) and (stat_filter=="Alle" or a["status"]==stat_filter)]
    if filtered:
        ref = st.selectbox("Anfrage waehlen", [a["referenz"] for a in filtered], format_func=lambda x: f"{x} — {[a['betreff'] for a in filtered if a['referenz']==x][0]}")
        a = db.get_anfrage(ref)
        if a:
            st.markdown(f"**{a['betreff']}** | {a['kategorie']} | {a['prioritaet']}")
            st.caption(f"Von: {a['absender']} | {a['erstellt_am']} | Ref: {a['referenz']}")
            st.markdown(f"**Nachricht:**\n\n{a['nachricht']}")
            st.divider()
            if a.get("antwort_json"):
                ant = json.loads(a["antwort_json"]) if isinstance(a["antwort_json"],str) else a["antwort_json"]
                if ant.get("demo_mode"): st.caption("⚠️ Demo-Modus")
                st.subheader("🤖 KI-Antwort")
                st.markdown(ant.get("antwort",""))
                st.caption(f"Weiterleitung: {ant.get('weiterleitung_an','')} | Dringlichkeit: {ant.get('dringlichkeit','')}")
            if st.button("🤖 KI-Antwort generieren", type="primary"):
                with st.spinner("KI analysiert..."):
                    ant = st.session_state.analyzer.analyze(a)
                    db.update_status(ref, "beantwortet", ant)
                    st.success("Antwort generiert!")
                    st.rerun()
            st.divider()
            c1,c2,c3 = st.columns(3)
            with c1:
                if st.button("✅ Beantwortet"): db.update_status(ref,"beantwortet"); st.rerun()
            with c2:
                if st.button("⏳ In Bearbeitung"): db.update_status(ref,"in_bearbeitung"); st.rerun()
            with c3:
                if st.button("🔒 Geschlossen"): db.update_status(ref,"geschlossen"); st.rerun()

elif page == "➕ Neue Anfrage":
    st.title("➕ Neue Anfrage")
    with st.form("neu"):
        c1,c2=st.columns(2)
        with c1:
            ref=st.text_input("Referenz*","BA-2026-0021")
            absender=st.text_input("Absender*","Max Mustermann")
        with c2:
            kat=st.selectbox("Kategorie*",["Muell/Abfall","Strassen/Verkehr","Anmeldung/Ausweis","Beschwerde","Auskunft"])
            prio=st.selectbox("Prioritaet*",["hoch","mittel","niedrig"])
        betreff=st.text_input("Betreff*")
        nachricht=st.text_area("Nachricht*",height=150)
        if st.form_submit_button("💾 Speichern",type="primary",use_container_width=True):
            if not ref or not betreff or not nachricht: st.error("Pflichtfelder ausfuellen!")
            elif db.create_anfrage(ref,betreff,kat,prio,absender,nachricht): st.success("Gespeichert!"); st.balloons(); st.rerun()
            else: st.error("Referenz existiert bereits!")

elif page == "⚙️ Einstellungen":
    st.title("⚙️ Einstellungen")
    st.subheader("🤖 KI-Konfiguration")
    c1,c2=st.columns(2)
    with c1:
        ollama_url=st.text_input("Ollama Server",db.get_setting("ollama_url","http://localhost:11434"))
        model=st.text_input("Modell",db.get_setting("ollama_model","llama3.1:8b"))
    with c2:
        temp=st.text_input("Temperatur",db.get_setting("ollama_temperature","0.2"))
        tokens=st.text_input("Max Tokens",db.get_setting("ollama_max_tokens","4096"))
    if st.button("Speichern"):
        for k,v in [("ollama_url",ollama_url),("ollama_model",model),("ollama_temperature",temp),("ollama_max_tokens",tokens)]:
            db.set_setting(k,v)
        st.session_state.analyzer=AnfragenAnalyzer(ollama_url,model)
        st.success("Gespeichert!")
    st.subheader("🏛️ Behoerde")
    behoerde=st.text_input("Behoerde",db.get_setting("behoerde","Stadtverwaltung Musterhausen"))
    if st.button("Behoerde speichern"): db.set_setting("behoerde",behoerde); st.success("Gespeichert!")
    st.divider()
    st.markdown("🔒 **100% DSGVO-konform | Self-Hosted | Ollama**")
