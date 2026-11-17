"""Extrai o texto de cada .docx (parágrafos e células de tabela, em ordem)
para comparar com os .md. Uso: python -I docx_texto.py <pasta_docx> <saida>"""
import os
import sys
import zipfile
import xml.etree.ElementTree as ET

W = '{http://schemas.openxmlformats.org/wordprocessingml/2006/main}'


def texto_par(p):
    partes = []
    for el in p.iter():
        if el.tag == W + 't':
            partes.append(el.text or '')
        elif el.tag == W + 'tab':
            partes.append('\t')
        elif el.tag == W + 'br':
            partes.append('\n')
    return ''.join(partes)


def extrair(caminho):
    with zipfile.ZipFile(caminho) as z:
        raiz = ET.fromstring(z.read('word/document.xml'))
        imagens = [n for n in z.namelist() if n.startswith('word/media/')]
    corpo = raiz.find(W + 'body')
    linhas = []
    for bloco in corpo:
        if bloco.tag == W + 'p':
            t = texto_par(bloco).strip()
            if t:
                linhas.append(t)
        elif bloco.tag == W + 'tbl':
            for tr in bloco.iter(W + 'tr'):
                celulas = []
                for tc in tr.iter(W + 'tc'):
                    celulas.append(' '.join(
                        texto_par(p).strip() for p in tc.iter(W + 'p') if texto_par(p).strip()))
                linhas.append('| ' + ' | '.join(celulas) + ' |')
    return linhas, imagens


pasta, saida = sys.argv[1], sys.argv[2]
os.makedirs(saida, exist_ok=True)
for nome in sorted(os.listdir(pasta)):
    if not nome.endswith('.docx'):
        continue
    linhas, imagens = extrair(os.path.join(pasta, nome))
    with open(os.path.join(saida, nome.replace('.docx', '.txt')), 'w', encoding='utf-8') as f:
        f.write('\n'.join(linhas) + '\n')
    print(f'{nome}: {len(linhas)} blocos, {len(imagens)} imagens {imagens}')
