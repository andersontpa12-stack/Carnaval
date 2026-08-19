# ======================================================
# Sistema Integrado — Escolas de Samba de SP (Versão Web)
# ======================================================

import json, time, re, html, random, io
import pandas as pd
import streamlit as st
from pathlib import Path

# ---------------- CONFIGURAÇÃO ----------------
ARQUIVO_DADOS = "dados_escolas.json"
ARQUIVO_CSV = "dados_escolas.csv"

# ---------------- LISTAS E CORES ----------------
escolas_por_grupo = {
    'Grupo Especial': ["Mocidade Unida da Mooca","Colorado do Brás","Dragões da Real","Acadêmicos do Tatuapé",
                       "Rosas de Ouro","Vai-Vai","Barroca Zona Sul","Império de Casa Verde","Águia de Ouro",
                       "Mocidade Alegre","Gaviões da Fiel","Estrela do Terceiro Milênio","Tom Maior","Camisa Verde e Branco"],
    'Acesso 1': ["Camisa 12","Unidos de Vila Maria","Acadêmicos do Tucuruvi","Mancha Verde",
                 "Nenê de Vila Matilde","Pérola Negra","Dom Bosco de Itaquera","Independente Tricolor"],
    'Acesso 2': ["Amizade Zona Leste","Imperatriz da Paulicéia","Torcida Jovem","X-9 Paulistana",
                 "Unidos de São Lucas","Unidos do Peruche","Morro da Casa Verde","Imperador do Ipiranga",
                 "Uirapuru da Mooca","Primeira da Cidade Líder"],
    'Especial de Bairros': ["Combinados de Sapopemba","Unidos de São Miguel","Saudosa Maloca","Brinco da Marquesa",
                            "Leandro de Itaquera","Penha","Raízes do Samba","Lavapés","Acadêmicos de São Jorge",
                            "Unidos de Santa Bárbara","Unidos do Vale Encantado","Filhos da Santa"],
    'Acesso de Bairros 1': ["Flor de Vila Dalila","União Independente da Zona Sul","União Imperial","Mocidade Robruense",
                            "Tradição Albertinense","Unidos de Guaianases","Cacique do Parque","União da Vila Albertina",
                            "Império Lapeano","Império Real","Isso Memo","Prova de Fogo"],
    'Acesso de Bairros 2': ["Acadêmicos do Ipiranga","Acadêmicos do Butantã","Passo de Ouro","Jóia da Coroa",
                            "Príncipe Negro","Imperial da Vila Penteado","Torcida Uniformizada do Palmeiras",
                            "Zumbi Zaire","Os Bambas","Flor de Liz","Oba Oba"],
    'Acesso de Bairros 3': ["Unidos do Jardim Primavera","Dragões de Vila Alpina","Explosão da Zona Norte",
                            "Só Vou se Você For","Mocidade Amigos do Graja","Estação Invernada","Iracema Meu Grande Amor",
                            "Estrela Cadente","Acadêmicos do Campo Limpo","Unidos do Jaçanã","Império do Samba COHAB II",
                            "Cabeções de Vila Prudente","Leões Zona Oeste","Em Cima da Hora Paulistana"],
    'Blocos de Fantasia': ["Pavilhão 9","Caprichosos da Zona Sul","Império do Morro","Unidos do Abaeté","Garotos da Vila Santa Maria",
                           "Chorões da Tia Gê","Unidos do Palmares","Inajar de Souza","Imperatriz do Jaraguá",
                           "União da Trindade","Unidos do Pé Grande","Não Empurra Que É Pior","Unidos do Guaraú",
                           "Mocidade Amazonense","Mocidade Independente da Zona Leste","Vovó Bolão","Caprichosos do Piqueri","Kacike da Vila"]
}

cores_grupo = {
    'Grupo Especial': '#1F618D',
    'Acesso 1': '#2874A6',
    'Acesso 2': '#2E86C1',
    'Especial de Bairros': '#1ABC9C',
    'Acesso de Bairros 1': '#16A085',
    'Acesso de Bairros 2': '#27AE60',
    'Acesso de Bairros 3': '#2ECC71',
    'Blocos de Fantasia': '#F39C12'
}

COLUMNS = ['nome','grupo','sede','fundacao','presidente','mestre_sala',
           'porta_bandeira','mestre_de_bateria','escola_madrinha','brasao','enredo_2026']

TYPING_DELAY = 0.05
MAX_PREVIEW = 600

# ---------------- FUNÇÕES DE DADOS ----------------
def load_data():
    """Carrega dados do JSON ou cria tabela inicial"""
    if Path(ARQUIVO_DADOS).exists():
        try:
            with open(ARQUIVO_DADOS, 'r', encoding='utf-8') as f:
                data = pd.DataFrame(json.load(f))
            for c in COLUMNS:
                if c not in data.columns: data[c] = ""
            return data[COLUMNS].fillna("")
        except Exception: pass
    
    rows = []
    for grupo, lista in escolas_por_grupo.items():
        for nome in lista:
            rows.append({col:"" for col in COLUMNS})
            rows[-1]['nome'] = nome
            rows[-1]['grupo'] = grupo
    return pd.DataFrame(rows, columns=COLUMNS).fillna("")

def save_data(df):
    """Salva dados em JSON e CSV"""
    df.to_json(ARQUIVO_DADOS, orient='records', force_ascii=False, indent=2)
    df.to_csv(ARQUIVO_CSV, index=False, encoding='utf-8-sig')

# ---------------- INICIALIZA SESSÃO ----------------
if 'df' not in st.session_state:
    st.session_state.df = load_data()
if 'mostrar_completo' not in st.session_state:
    st.session_state.mostrar_completo = False

df = st.session_state.df

# ---------------- INTERFACE WEB ----------------
st.set_page_config(page_title="Escolas de Samba — SP", page_icon="🎭", layout="wide")
st.title("🎭 Sistema de Cadastro — Escolas de Samba de São Paulo")
st.markdown("---")

# --- BARRA LATERAL: LISTA POR GRUPO ---
with st.sidebar:
    st.header("📋 Escolas por Grupo")
    grupo_selecionado = st.selectbox("Filtrar por grupo:", ["Todos"] + list(escolas_por_grupo.keys()))
    
    filtro = df if grupo_selecionado == "Todos" else df[df['grupo'] == grupo_selecionado]
    nomes_escolas = sorted(filtro['nome'].tolist())
    
    st.subheader(f"{len(nomes_escolas)} escolas")
    nome_escolhida = st.selectbox("Selecione uma escola:", [""] + nomes_escolas)

# --- FORMULÁRIO ---
st.header("📝 Dados da Escola")
dados_escola = df[df['nome'] == nome_escolhida].iloc[0] if nome_escolhida else {}

col1, col2, col3 = st.columns(3)
with col1: grupo_atual = st.selectbox("Grupo:", list(escolas_por_grupo.keys()), 
    index=list(escolas_por_grupo.keys()).index(dados_escola.get('grupo', 'Grupo Especial')) if dados_escola else 0)
with col2: nome_edit = st.text_input("Nome da Escola:", value=dados_escola.get('nome', '') if dados_escola else '')
with col3: sede = st.text_input("Sede:", value=dados_escola.get('sede', '') if dados_escola else '')

col4, col5, col6 = st.columns(3)
with col4: fundacao = st.text_input("Fundação:", value=dados_escola.get('fundacao', '') if dados_escola else '')
with col5: presidente = st.text_input("Presidente:", value=dados_escola.get('presidente', '') if dados_escola else '')
with col6: madrinha = st.text_input("Escola-Madrinha:", value=dados_escola.get('escola_madrinha', '') if dados_escola else '')

col7, col8, col9 = st.columns(3)
with col7: mestre_sala = st.text_input("Mestre-Sala:", value=dados_escola.get('mestre_sala', '') if dados_escola else '')
with col8: porta_band = st.text_input("Porta-Bandeira:", value=dados_escola.get('porta_bandeira', '') if dados_escola else '')
with col9: bateria = st.text_input("Mestre de Bateria:", value=dados_escola.get('mestre_de_bateria', '') if dados_escola else '')

enredo = st.text_area("Enredo 2026:", value=dados_escola.get('enredo_2026', '') if dados_escola else '', height=150)
brasao_url = st.text_input("Brasão (URL ou link):", value=dados_escola.get('brasao', '') if dados_escola else '')

# --- BOTÕES ---
col_a, col_b, col_c, col_d = st.columns(4)
salvar = col_a.button("💾 Salvar Dados", type="primary")
pesquisar = col_b.button("🔎 Exibir Cartão")
buscar_btn = col_c.button("🔍 Buscar Enredo")
relatorio_btn = col_d.button("📊 Relatório")

busca_termo = st.text_input("Buscar palavra no enredo:", placeholder="Digite um termo...")

st.markdown("---")

# --- AÇÃO: SALVAR ---
if salvar and nome_edit:
    idx = df.index[df['nome'].str.lower() == nome_edit.lower()].tolist()
    novo = {
        'nome': nome_edit.strip(), 'grupo': grupo_atual, 'sede': sede, 'fundacao': fundacao,
        'presidente': presidente, 'mestre_sala': mestre_sala, 'porta_bandeira': porta_band,
        'mestre_de_bateria': bateria, 'escola_madrinha': madrinha,
        'brasao': brasao_url, 'enredo_2026': enredo
    }
    if idx:
        for k, v in novo.items(): df.at[idx[0], k] = v
    else:
        df = pd.concat([df, pd.DataFrame([novo])], ignore_index=True)
    save_data(df)
    st.session_state.df = df
    st.success(f"✅ Escola '{nome_edit}' salva com sucesso!")
    st.rerun()

# --- AÇÃO: CARTÃO COM ANIMAÇÃO ---
if pesquisar and nome_escolhida:
    st.subheader("📇 Cartão da Escola")
    with st.spinner("Gerando cartão..."):
        time.sleep(1)
    row = df[df['nome'] == nome_escolhida].iloc[0]
    cor = cores_grupo.get(row['grupo'], '#777')
    texto_enredo = row['enredo_2026'] or ""
    
    # Animação de digitação
    preview = texto_enredo[:MAX_PREVIEW] + ("..." if len(texto_enredo) > MAX_PREVIEW else "")
    card_html = f"""
    <div style='border:3px solid {cor}; border-radius:12px; padding:20px; background:linear-gradient(to bottom,#fff,#f8f9fa); box-shadow:0 4px 12px rgba(0,0,0,0.08);'>
        <h2 style='color:{cor}; margin-top:0;'>{html.escape(row['nome'])}</h2>
        <strong>Grupo:</strong> {html.escape(row['grupo'])}<br>
        <strong>Sede:</strong> {html.escape(row['sede'])} &nbsp;|&nbsp; <strong>Fundação:</strong> {html.escape(row['fundacao'])}<br>
        <strong>Presidente:</strong> {html.escape(row['presidente'])}<br>
        <strong>Mestre-Sala:</strong> {html.escape(row['mestre_sala'])} &nbsp;|&nbsp; <strong>Porta-Bandeira:</strong> {html.escape(row['porta_bandeira'])}<br>
        <strong>Mestre de Bateria:</strong> {html.escape(row['mestre_de_bateria'])}<br>
        <strong>Escola-Madrinha:</strong> {html.escape(row['escola_madrinha'])}<br><br>
        <strong>Enredo:</strong><br><div style='white-space:pre-wrap;'>{html.escape(texto_enredo if st.session_state.mostrar_completo else preview)}</div>
    </div>"""
    st.markdown(card_html, unsafe_allow_html=True)
    if len(texto_enredo) > MAX_PREVIEW and not st.session_state.mostrar_completo:
        if st.button("▼ Mostrar enredo completo"):
            st.session_state.mostrar_completo = True
            st.rerun()
    if brasao_url:
        st.image(brasao_url, width=250)

# --- AÇÃO: BUSCA ENREDO ---
if buscar_btn and busca_termo:
    res = df[df['enredo_2026'].str.lower().str.contains(busca_termo.lower(), na=False)]
    if res.empty:
        st.info(f"Nenhum enredo contém '{busca_termo}'.")
    else:
        st.subheader(f"🔍 {len(res)} resultado(s) encontrados:")
        for _, r in res.iterrows():
            st.markdown(f"**{r['nome']} — {r['grupo']}**")
            st.text(r['enredo_2026'][:800] + ("..." if len(r['enredo_2026'])>800 else ""))
            st.divider()

# --- AÇÃO: RELATÓRIO ---
if relatorio_btn:
    st.subheader("📊 Relatório Completo")
    st.info(f"Total de escolas cadastradas: {len(df)}")
    st.bar_chart(df['grupo'].value_counts())
    col_a, col_b, col_c, col_d = st.columns(4)
    col_a.metric("Com Mestre-Sala", len(df[df['mestre_sala'].str.strip()!=""]))
    col_b.metric("Com Porta-Bandeira", len(df[df['porta_bandeira'].str.strip()!=""]))
    col_c.metric("Com Enredo", len(df[df['enredo_2026'].str.strip()!=""]))
    col_d.metric("Com Brasão", len(df[df['brasao'].str.strip()!=""]))

# --- EXPORTAÇÃO ---
st.download_button("📥 Baixar CSV", data=df.to_csv(index=False, encoding='utf-8-sig'),
                   file_name="escolas_samba_sp.csv", mime="text/csv")

st.markdown("---")
st.caption("🚀 Sistema hospedado com atualização automática — Dados salvos automaticamente")
