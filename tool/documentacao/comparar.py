"""Compara o texto dos .docx com os .md (formatação ignorada).
Uso: python -I comparar.py <pasta_txt> <raiz_projeto> <saida>"""
import difflib
import os
import re
import sys

PARES = {
    'Definicao_dos_Stakeholders_Phize_corrigido': 'stakeholders',
    'Descricao_UC_Phize_corrigido': 'casos-de-uso',
    'Especificacao_da_Arquitetura_Phize_corrigido': 'arquitetura',
    'Relatorio_Completo_Phize_corrigido': 'relatorio-completo',
    'Requisitos_de_Software_Phize_corrigido': 'requisitos',
    'UML_Phize_corrigido': 'uml',
    'Viabilidade_e_Posicionamento_Phize_corrigido': 'viabilidade',
}


def norm(linha):
    l = linha.replace('**', '').replace('\\', '').replace('`', '')
    l = re.sub(r'^#+\s*', '', l)
    l = re.sub(r'^\s*(?:[-*]|\d+\.)\s+', '', l)
    l = re.sub(r'(?<!\w)\*(?!\s)|(?<!\s)\*(?!\w)', '', l)
    l = re.sub(r'\s+', ' ', l).strip()
    return l


def linhas_md(texto):
    saida = []
    for l in texto.splitlines():
        if re.match(r'^\s*\|?\s*:?-{3,}', l):
            continue
        n = norm(l)
        if n:
            saida.append(n)
    return saida


pasta, raiz, saida = sys.argv[1:4]
with open(saida, 'w', encoding='utf-8') as out:
    for docx, md in PARES.items():
        d = [norm(l) for l in open(os.path.join(pasta, docx + '.txt'), encoding='utf-8').read().splitlines()]
        d = [l for l in d if l]
        m = linhas_md(open(os.path.join(raiz, 'docs', md + '.md'), encoding='utf-8').read())
        sm = difflib.SequenceMatcher(None, d, m, autojunk=False)
        mudancas = [op for op in sm.get_opcodes() if op[0] != 'equal']
        out.write(f'\n######## {docx}.docx  x  docs/{md}.md  — {len(mudancas)} trechos diferentes\n')
        for tag, i1, i2, j1, j2 in mudancas:
            out.write(f'\n--- [{tag}] docx {i1}-{i2} / md {j1}-{j2}\n')
            for l in d[i1:i2]:
                out.write(f'  DOCX: {l}\n')
            for l in m[j1:j2]:
                out.write(f'  MD  : {l}\n')
        print(f'{docx}: {len(mudancas)} trechos diferentes')
