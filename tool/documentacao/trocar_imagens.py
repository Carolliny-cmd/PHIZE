"""Troca as imagens dos diagramas no .docx do UML, em alterações controladas:
a imagem antiga fica apagada (riscada) e a nova, inserida logo depois.

Uso: python -I trocar_imagens.py <entrada.docx> <saida.docx> rIdA=img1.png rIdB=img2.png ...
"""
import datetime
import re
import struct
import sys
import zipfile

AUTOR = 'Claude (atualização da documentação)'
DATA = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
LARGURA_MAX = 5731200      # EMU: largura útil da página A4 com margens de 2,54 cm
ALTURA_MAX = 8000000       # EMU: deixa espaço para a legenda na mesma página


def tamanho_png(dados):
    return struct.unpack('>II', dados[16:24])


def main():
    entrada, saida = sys.argv[1], sys.argv[2]
    trocas = dict(a.split('=', 1) for a in sys.argv[3:])
    zin = zipfile.ZipFile(entrada)
    doc = zin.read('word/document.xml').decode('utf-8')
    rels = zin.read('word/_rels/document.xml.rels').decode('utf-8')
    novos_arquivos = {}
    proximo = 9100
    for n, (rid_velho, png) in enumerate(trocas.items(), start=1):
        dados = open(png, 'rb').read()
        w, h = tamanho_png(dados)
        nome = f'diagrama_atualizado_{n:02d}.png'
        rid_novo = f'rIdDiagrama{n}'
        novos_arquivos[f'word/media/{nome}'] = dados
        rels = rels.replace('</Relationships>', f'<Relationship Id="{rid_novo}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/{nome}"/></Relationships>')
        m = re.search(r'<w:r(?: [^>]*)?>(?:(?!</w:r>).)*?<w:drawing>(?:(?!</w:r>).)*?r:embed="' + rid_velho + r'".*?</w:r>', doc, re.S)
        assert m, rid_velho
        velho = m.group(0)
        cx_velho = int(re.search(r'<wp:extent cx="(\d+)"', velho).group(1))
        cx = LARGURA_MAX
        cy = int(cx * h / w)
        if cy > ALTURA_MAX:
            cy = ALTURA_MAX
            cx = int(cy * w / h)
        novo = velho.replace(f'r:embed="{rid_velho}"', f'r:embed="{rid_novo}"')
        novo = re.sub(r'<wp:extent cx="\d+" cy="\d+"/>', f'<wp:extent cx="{cx}" cy="{cy}"/>', novo)
        novo = re.sub(r'<a:ext cx="\d+" cy="\d+"/>', f'<a:ext cx="{cx}" cy="{cy}"/>', novo)
        proximo += 1
        novo = re.sub(r'<wp:docPr id="\d+" name="[^"]*"', f'<wp:docPr id="{proximo}" name="{nome}"', novo)
        novo = re.sub(r'<pic:cNvPr id="\d+" name="[^"]*"', f'<pic:cNvPr id="0" name="{nome}"', novo)
        trocado = (f'<w:del w:id="{proximo + 500}" w:author="{AUTOR}" w:date="{DATA}">{velho}</w:del>'
                   f'<w:ins w:id="{proximo + 600}" w:author="{AUTOR}" w:date="{DATA}">{novo}</w:ins>')
        doc = doc.replace(velho, trocado, 1)
        print(f'{rid_velho}: {png.split("/")[-1]} {w}x{h} -> {cx / 360000:.1f} x {cy / 360000:.1f} cm')
    with zipfile.ZipFile(saida, 'w', zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            if item.filename.endswith('/'):
                continue
            if item.filename == 'word/document.xml':
                zout.writestr(item, doc.encode('utf-8'))
            elif item.filename == 'word/_rels/document.xml.rels':
                zout.writestr(item, rels.encode('utf-8'))
            else:
                zout.writestr(item, zin.read(item.filename))
        for nome, dados in novos_arquivos.items():
            zout.writestr(nome, dados)


if __name__ == '__main__':
    main()
