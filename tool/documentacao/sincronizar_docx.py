"""Leva o texto de um .docx ao do .md correspondente, com alterações
controladas (w:ins / w:del), preservando a formatação do Word.

Edita o XML como texto: só os parágrafos alterados são reescritos; o resto
do arquivo fica byte a byte igual.

Uso: python -I sincronizar_docx.py <entrada.docx> <arquivo.md> <saida.docx> [--relatorio arq]
"""
import datetime
import difflib
import html
import re
import sys
import zipfile

AUTOR = 'Claude (atualização da documentação)'
DATA = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
_id = [9000]


def novo_id():
    _id[0] += 1
    return _id[0]


# ---------------------------------------------------------------- texto


def norm(linha):
    l = linha.replace('**', '').replace('\\', '').replace('`', '')
    l = re.sub(r'^#+\s*', '', l)
    l = re.sub(r'^\s*(?:[-*]|\d+\.)\s+', '', l)
    l = re.sub(r'(?<!\w)\*(?!\s)|(?<!\s)\*(?!\w)', '', l)
    return re.sub(r'\s+', ' ', l).strip()


def limpar_md(texto):
    """Texto final de uma linha do .md, sem marcação."""
    t = texto.replace('`', '')
    t = re.sub(r'\\(.)', r'\1', t)
    t = t.replace('**', '')
    t = re.sub(r'(?<!\w)\*(?=\S)(.+?)(?<=\S)\*(?!\w)', r'\1', t)
    return t.strip()


def segmentos_md(texto):
    """[(texto, negrito)] de uma linha do .md, para parágrafos novos."""
    t = texto.replace('`', '')
    t = re.sub(r'\\(.)', r'\1', t)
    partes = []
    pos = 0
    for m in re.finditer(r'\*\*(.+?)\*\*', t):
        if m.start() > pos:
            partes.append((t[pos:m.start()], False))
        partes.append((m.group(1), True))
        pos = m.end()
    if pos < len(t):
        partes.append((t[pos:], False))
    return [(re.sub(r'(?<!\w)\*(?=\S)(.+?)(?<=\S)\*(?!\w)', r'\1', s), b) for s, b in partes if s]


def tokens(t):
    return re.findall(r'\s+|\w+|[^\w\s]', t)


# ---------------------------------------------------------------- docx


def texto_par(p):
    return html.unescape(''.join(re.findall(r'<w:t(?: [^>]*)?>([^<]*)</w:t>', p)))


RE_FILHO = re.compile(
    r'(<w:r(?: [^>]*)?>.*?</w:r>)|(<w:proofErr[^>]*/>)|(<w:bookmarkStart[^>]*/>)'
    r'|(<w:bookmarkEnd[^>]*/>)|(<w:lastRenderedPageBreak/>)', re.S)


def desmontar(p):
    """(abertura, pPr, [(rPr, texto)], extras) ou None se houver algo inesperado."""
    m = re.match(r'(<w:p(?: [^>]*)?>)(<w:pPr>.*?</w:pPr>)?(.*)</w:p>$', p, re.S)
    if not m:
        return None
    abertura, ppr, resto = m.group(1), m.group(2) or '', m.group(3)
    runs, extras, pos = [], [], 0
    for f in RE_FILHO.finditer(resto):
        if f.start() != pos:
            return None
        pos = f.end()
        if f.group(1):
            r = f.group(1)
            corpo = re.sub(r'^<w:r(?: [^>]*)?>|</w:r>$', '', r)
            rpr = re.search(r'<w:rPr>.*?</w:rPr>', corpo, re.S)
            rpr = rpr.group(0) if rpr else ''
            sem_rpr = corpo.replace(rpr, '', 1)
            if re.sub(r'<w:t(?: [^>]*)?>[^<]*</w:t>|<w:lastRenderedPageBreak/>', '', sem_rpr).strip():
                return None  # tab, quebra, desenho...
            runs.append((rpr, texto_par(r)))
        elif f.group(3) or f.group(4):
            extras.append(f.group(0))
    if pos != len(resto):
        return None
    return abertura, ppr, runs, extras


def esc(t):
    return t.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


def run(rpr, t):
    return f'<w:r>{rpr}<w:t xml:space="preserve">{esc(t)}</w:t></w:r>'


def run_del(rpr, t):
    return (f'<w:del w:id="{novo_id()}" w:author="{AUTOR}" w:date="{DATA}">'
            f'<w:r>{rpr}<w:delText xml:space="preserve">{esc(t)}</w:delText></w:r></w:del>')


def run_ins(rpr, t):
    return (f'<w:ins w:id="{novo_id()}" w:author="{AUTOR}" w:date="{DATA}">'
            f'{run(rpr, t)}</w:ins>')


def reescrever(p, novo):
    """Parágrafo com o texto novo, em alterações controladas palavra a palavra."""
    partes = desmontar(p)
    if partes is None:
        return None
    abertura, ppr, runs, extras = partes
    if not runs:
        return None
    velho = ''.join(t for _, t in runs)
    # Faixa de caracteres de cada run.
    faixas, pos = [], 0
    for rpr, t in runs:
        faixas.append((pos, pos + len(t), rpr))
        pos += len(t)

    def rpr_em(i):
        for a, b, rpr in faixas:
            if a <= i < b:
                return rpr
        return faixas[-1][2]

    tv, tn = tokens(velho), tokens(novo)
    sm = difflib.SequenceMatcher(None, tv, tn, autojunk=False)
    cv = [0]
    for t in tv:
        cv.append(cv[-1] + len(t))
    opcodes = sm.get_opcodes()
    if sm.ratio() < 0.5:
        # Muito reescrito: mantém começo e fim iguais e troca o miolo de uma
        # vez, para a alteração ficar legível no Word.
        ini = 0
        while ini < min(len(tv), len(tn)) and tv[ini] == tn[ini]:
            ini += 1
        fim = 0
        while fim < min(len(tv), len(tn)) - ini and tv[-1 - fim] == tn[-1 - fim]:
            fim += 1
        opcodes = []
        if ini:
            opcodes.append(('equal', 0, ini, 0, ini))
        opcodes.append(('replace', ini, len(tv) - fim, ini, len(tn) - fim))
        if fim:
            opcodes.append(('equal', len(tv) - fim, len(tv), len(tn) - fim, len(tn)))
    saida = []

    def emitir_velho(a, b, apagar):
        # Corta [a,b) nas fronteiras dos runs, mantendo cada formatação.
        for ra, rb, rpr in faixas:
            x, y = max(a, ra), min(b, rb)
            if x < y:
                trecho = velho[x:y]
                saida.append(run_del(rpr, trecho) if apagar else run(rpr, trecho))

    # Ilhas iguais curtas (até 3 letras, como "de" ou "a") entre duas
    # mudanças são absorvidas: a alteração vira um bloco legível.
    juntou = True
    while juntou:
        juntou = False
        for k in range(1, len(opcodes) - 1):
            tag, i1, i2, j1, j2 = opcodes[k]
            if tag == 'equal' and opcodes[k - 1][0] != 'equal' and opcodes[k + 1][0] != 'equal'                     and len(''.join(tv[i1:i2]).strip()) <= 3:
                a0, b0 = opcodes[k - 1], opcodes[k + 1]
                opcodes[k - 1:k + 2] = [('replace', a0[1], b0[2], a0[3], b0[4])]
                juntou = True
                break
    for tag, i1, i2, j1, j2 in opcodes:
        a, b = cv[i1], cv[i2]
        if tag == 'equal':
            emitir_velho(a, b, False)
        else:
            if tag in ('replace', 'delete'):
                emitir_velho(a, b, True)
            if tag in ('replace', 'insert'):
                saida.append(run_ins(rpr_em(a if a < len(velho) else max(a - 1, 0)), ''.join(tn[j1:j2])))
    return abertura + ppr + ''.join(extras) + ''.join(saida) + '</w:p>'


def ppr_inserido(ppr):
    """pPr do parágrafo novo, com a marca de parágrafo inserida."""
    marca = f'<w:ins w:id="{novo_id()}" w:author="{AUTOR}" w:date="{DATA}"/>'
    if not ppr:
        return f'<w:pPr><w:rPr>{marca}</w:rPr></w:pPr>'
    if '<w:rPr>' in ppr:
        return re.sub(r'<w:rPr>', '<w:rPr>' + marca, ppr, count=1)
    return ppr.replace('</w:pPr>', f'<w:rPr>{marca}</w:rPr></w:pPr>')


def ppr_apagado(ppr):
    marca = f'<w:del w:id="{novo_id()}" w:author="{AUTOR}" w:date="{DATA}"/>'
    if not ppr:
        return f'<w:pPr><w:rPr>{marca}</w:rPr></w:pPr>'
    if '<w:rPr>' in ppr:
        return re.sub(r'<w:rPr>', '<w:rPr>' + marca, ppr, count=1)
    return ppr.replace('</w:pPr>', f'<w:rPr>{marca}</w:rPr></w:pPr>')


def negrito(rpr):
    return bool(re.search(r'<w:b/>|<w:b w:val="(?:1|true|on)"/>', rpr))


def sem_negrito(rpr):
    r = re.sub(r'<w:b(?: w:val="[^"]*")?/>|<w:bCs(?: w:val="[^"]*")?/>', '', rpr)
    return '' if r == '<w:rPr></w:rPr>' else r


def com_negrito(rpr):
    if negrito(rpr):
        return rpr
    if not rpr:
        return '<w:rPr><w:b/><w:bCs/></w:rPr>'
    return rpr.replace('<w:rPr>', '<w:rPr><w:b/><w:bCs/>', 1)


def paragrafo_novo(modelo, linha_md, texto_literal=None):
    """Parágrafo inserido, com o estilo do parágrafo modelo."""
    partes = desmontar(modelo)
    if partes is None:
        abertura, ppr, runs = '<w:p>', '', []
    else:
        abertura, ppr, runs, _ = partes
    abertura = re.sub(r' w14:paraId="[^"]*"| w14:textId="[^"]*"', '', abertura)
    rpr_neg = next((r for r, _ in runs if negrito(r)), None)
    rpr_nor = next((r for r, _ in runs if not negrito(r)), None)
    if rpr_nor is None:
        rpr_nor = sem_negrito(rpr_neg or '')
    if rpr_neg is None:
        rpr_neg = com_negrito(rpr_nor)
    if texto_literal is not None:
        segs = [(texto_literal, False)]
        # Título: todo em negrito se o modelo é todo em negrito.
        if runs and all(negrito(r) for r, t in runs if t.strip()):
            segs = [(texto_literal, True)]
    else:
        segs = segmentos_md(linha_md)
    corpo = ''.join(run_ins(rpr_neg if b else rpr_nor, s) for s, b in segs)
    return abertura + ppr_inserido(ppr) + corpo + '</w:p>'


def apagar_paragrafo(p):
    partes = desmontar(p)
    if partes is None:
        return None
    abertura, ppr, runs, extras = partes
    return abertura + ppr_apagado(ppr) + ''.join(extras) + ''.join(
        run_del(r, t) for r, t in runs if t) + '</w:p>'


# ---------------------------------------------------------------- unidades


def unidades_docx(xml):
    corpo_ini = xml.index('<w:body>') + len('<w:body>')
    corpo_fim = xml.rindex('</w:body>')
    unidades = []
    for m in re.finditer(r'(<w:tbl>.*?</w:tbl>)|(<w:p[ >].*?</w:p>)', xml[corpo_ini:corpo_fim], re.S):
        base = corpo_ini + m.start()
        if m.group(1):
            for c in re.finditer(r'<w:tc>.*?</w:tc>', m.group(1), re.S):
                ps = [(base + c.start() + pm.start(), base + c.start() + pm.end())
                      for pm in re.finditer(r'<w:p[ >].*?</w:p>', c.group(0), re.S)]
                txt = ' '.join(texto_par(xml[a:b]).strip() for a, b in ps if texto_par(xml[a:b]).strip())
                unidades.append({'tipo': 'celula', 'ps': ps, 'texto': txt})
        else:
            a, b = base, base + m.end() - m.start()
            t = texto_par(xml[a:b]).strip()
            if t:
                unidades.append({'tipo': 'p', 'ps': [(a, b)], 'texto': t})
    return unidades


def unidades_md(md):
    unidades = []
    for l in md.splitlines():
        if not l.strip() or re.match(r'^\s*\|?\s*:?-{3,}', l):
            continue
        if l.strip().startswith('|'):
            for c in [c.strip() for c in l.strip().strip('|').split(' | ')]:
                if norm(c):
                    unidades.append({'tipo': 'celula', 'linha': c, 'texto': norm(c)})
        elif norm(l):
            unidades.append({'tipo': 'p', 'linha': l, 'texto': norm(l)})
    return unidades


def forma(linha):
    s = linha.strip()
    if s.startswith('#'):
        return 'h' + str(len(s) - len(s.lstrip('#')))
    if re.match(r'^(?:[-*]|\d+\.)\s', s):
        return 'lista'
    m = re.match(r'^\*\*([^*:]+:)', s)
    if m:
        return 'rotulo:' + m.group(1).strip()
    return 'corpo'


# ---------------------------------------------------------------- células


def dividir_celula(texto_md, paragrafos_docx):
    """Divide o texto da célula do .md em pedaços como os parágrafos do .docx."""
    if any(re.match(r'^\d+\.\s', t) for t in paragrafos_docx):
        return [p.strip() for p in re.split(r'\s(?=\d+\.\s)', texto_md) if p.strip()]
    return [p.strip() for p in re.split(
        r'(?<=[.!?])\s+(?=[A-ZÁÉÍÓÚÂÊÔÃÕÇ“"])', texto_md) if p.strip()]


# ---------------------------------------------------------------- principal


def sincronizar(xml, md, relatorio):
    ud, um = unidades_docx(xml), unidades_md(md)
    sm = difflib.SequenceMatcher(None, [norm(u['texto']) for u in ud],
                                 [u['texto'] for u in um], autojunk=False)
    # Modelos de estilo: parágrafo do .docx casado com uma linha do .md.
    modelos = {}
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == 'equal':
            for k in range(i2 - i1):
                d, m = ud[i1 + k], um[j1 + k]
                if d['tipo'] == 'p':
                    modelos.setdefault(forma(m['linha']), []).append(d['ps'][0])
    edicoes = []  # (ini, fim, xml_novo)

    def modelo_para(linha, perto):
        f = forma(linha)
        candidatos = modelos.get(f) or (modelos.get('corpo') if f.startswith('rotulo') else None) \
            or modelos.get('corpo') or []
        if not candidatos:
            return None
        return min(candidatos, key=lambda ab: abs(ab[0] - perto))

    def trocar_paragrafo(ab, novo_texto, onde):
        p = xml[ab[0]:ab[1]]
        velho = texto_par(p)
        # Mantém o número ou marcador digitado no .docx, quando houver.
        prefixo = re.match(r'^\s*(\d+\.\s+)', velho)
        alvo = novo_texto
        if not prefixo:
            alvo = re.sub(r'^\s*(?:[-*]|\d+\.)\s+', '', alvo) if not re.match(r'^\d+\.\s', velho) else alvo
        r = reescrever(p, alvo)
        if r is None:
            relatorio.append(f'MANUAL ({onde}): parágrafo com estrutura especial: {velho[:80]}')
            return
        edicoes.append((ab[0], ab[1], r))
        relatorio.append(f'alterado: {velho[:70]} -> {alvo[:70]}')

    def inserir_depois(pos, linhas, perto):
        novos = []
        for l in linhas:
            mod = modelo_para(l, perto)
            texto = limpar_md(re.sub(r'^#+\s*', '', l.strip()))
            if forma(l) == 'lista':
                texto = re.sub(r'^(?:[-*]|\d+\.)\s+', '', texto)
                linha = re.sub(r'^\s*(?:[-*]|\d+\.)\s+', '', l.strip())
                novos.append(paragrafo_novo(xml[mod[0]:mod[1]] if mod else '<w:p></w:p>', linha))
            elif forma(l).startswith('h'):
                novos.append(paragrafo_novo(xml[mod[0]:mod[1]] if mod else '<w:p></w:p>', None, texto))
            else:
                linha = re.sub(r'^#+\s*', '', l.strip())
                novos.append(paragrafo_novo(xml[mod[0]:mod[1]] if mod else '<w:p></w:p>', linha))
            relatorio.append(f'inserido: {texto[:90]}')
        edicoes.append((pos, pos, ''.join(novos)))

    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == 'equal':
            continue
        ds, ms = ud[i1:i2], um[j1:j2]
        if any(u['tipo'] == 'celula' for u in ds + ms):
            if len(ds) != len(ms) or any(a['tipo'] != b['tipo'] for a, b in zip(ds, ms)):
                relatorio.append(f'MANUAL: tabela com linhas a mais ou a menos (docx {i1}-{i2}, md {j1}-{j2})')
                continue
            for d, m in zip(ds, ms):
                if norm(d['texto']) == m['texto']:
                    continue
                pars = [(ab, texto_par(xml[ab[0]:ab[1]]).strip()) for ab in d['ps']]
                pars = [(ab, t) for ab, t in pars if t]
                pedacos = dividir_celula(limpar_md(m['linha']), [t for _, t in pars])
                sm2 = difflib.SequenceMatcher(None, [norm(t) for _, t in pars], [norm(p) for p in pedacos], autojunk=False)
                for tg, a1, a2, b1, b2 in sm2.get_opcodes():
                    if tg == 'equal':
                        continue
                    alvo = pars[a1:a2]
                    novos = pedacos[b1:b2]
                    for k in range(min(len(alvo), len(novos))):
                        trocar_paragrafo(alvo[k][0], novos[k], 'célula')
                    for ab, t in alvo[len(novos):]:
                        r = apagar_paragrafo(xml[ab[0]:ab[1]])
                        edicoes.append((ab[0], ab[1], r))
                        relatorio.append(f'apagado: {t[:80]}')
                    if len(novos) > len(alvo):
                        ref = (alvo[-1][0] if alvo else pars[a1 - 1][0] if a1 > 0 else pars[0][0])
                        mod = xml[ref[0]:ref[1]]
                        extras = ''.join(paragrafo_novo(mod, None, t) for t in novos[len(alvo):])
                        edicoes.append((ref[1], ref[1], extras))
                        for t in novos[len(alvo):]:
                            relatorio.append(f'inserido na célula: {t[:80]}')
            continue
        # Parágrafos soltos: pares por semelhança, na ordem.
        pares = []
        jm = 0
        for d in ds:
            melhor, mj = 0.0, None
            for k in range(jm, len(ms)):
                pv, pn = norm(d['texto']).split(), ms[k]['texto'].split()
                cmp = difflib.SequenceMatcher(None, pv, pn, autojunk=False)
                cobertura = sum(b.size for b in cmp.get_matching_blocks()) / max(len(pv), 1)
                r = max(cmp.ratio(), cobertura if cobertura >= 0.6 else 0)
                if r > melhor:
                    melhor, mj = r, k
            if mj is not None and melhor >= 0.35:
                pares.append((d, mj))
                jm = mj + 1
            else:
                pares.append((d, None))
        usados = {mj for _, mj in pares if mj is not None}
        ultimo_fim = ud[i1 - 1]['ps'][-1][1] if i1 > 0 else None
        pendentes = []
        k_md = 0
        for d, mj in pares:
            if mj is not None:
                # linhas do .md antes deste par entram antes dele
                antes = [ms[k]['linha'] for k in range(k_md, mj) if k not in usados]
                if antes:
                    pos = d['ps'][0][0]
                    inserir_depois(pos, antes, pos)
                trocar_paragrafo(d['ps'][0], limpar_md(re.sub(r'^#+\s*', '', ms[mj]['linha'].strip())), 'parágrafo')
                k_md = mj + 1
                ultimo_fim = d['ps'][-1][1]
            else:
                r = apagar_paragrafo(xml[d['ps'][0][0]:d['ps'][0][1]])
                if r is None:
                    relatorio.append(f'MANUAL: apagar parágrafo especial: {d["texto"][:80]}')
                else:
                    edicoes.append((d['ps'][0][0], d['ps'][0][1], r))
                    relatorio.append(f'apagado: {d["texto"][:80]}')
                ultimo_fim = d['ps'][-1][1]
        resto = [ms[k]['linha'] for k in range(k_md, len(ms)) if k not in usados]
        if resto:
            if ultimo_fim is None:
                relatorio.append('MANUAL: inserção no início do documento')
            else:
                inserir_depois(ultimo_fim, resto, ultimo_fim)
    # Aplica de trás para a frente; inserções na mesma posição ficam em ordem.
    edicoes.sort(key=lambda e: (e[0], e[1]), reverse=True)
    for a, b, novo in edicoes:
        xml = xml[:a] + novo + xml[b:]
    return xml


def main():
    entrada, md_arq, saida = sys.argv[1:4]
    rel_arq = sys.argv[sys.argv.index('--relatorio') + 1] if '--relatorio' in sys.argv else None
    zin = zipfile.ZipFile(entrada)
    xml = zin.read('word/document.xml').decode('utf-8')
    md = open(md_arq, encoding='utf-8').read()
    relatorio = []
    novo = sincronizar(xml, md, relatorio)
    with zipfile.ZipFile(saida, 'w', zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            if item.filename.endswith('/'):
                continue
            dados = novo.encode('utf-8') if item.filename == 'word/document.xml' else zin.read(item.filename)
            zout.writestr(item, dados)
    texto = '\n'.join(relatorio)
    if rel_arq:
        open(rel_arq, 'w', encoding='utf-8').write(texto + '\n')
    print(f'{saida}: {sum(1 for r in relatorio if not r.startswith("MANUAL"))} mudanças, '
          f'{sum(1 for r in relatorio if r.startswith("MANUAL"))} para conferir à mão')


if __name__ == '__main__':
    main()
