"""Gera prints sintéticos de conversa a partir de um conjunto de avaliação.

Etapa 2 do plano do RAG (docs/calibracao-recuperacao.md, "Texto de print").
Cada mensagem do conjunto vira uma captura de tela fictícia, no formato de um
aplicativo de conversa genérico: barra de status, cabeçalho com o contato,
balões recebidos à esquerda, uma resposta da própria pessoa à direita,
horários e a barra de digitação. É o ruído que o OCR encontra num print
real e que o teste com frases limpas não mede.

Tudo é fictício: os textos vêm do conjunto (já mascarados), os contatos e
números do cabeçalho são inventados. As imagens vão para build/ (fora do
Git) e podem ser geradas de novo a qualquer momento.

    python -I tool/prints_sinteticos/gerar_prints.py
    python -I tool/prints_sinteticos/gerar_prints.py --arquivo teste.json --saida build/prints_sinteticos

Requer Pillow. Usa a fonte Segoe UI do Windows; em outro sistema, informe
--fonte com o caminho de uma fonte TrueType.
"""

import argparse
import json
import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

RAIZ = Path(__file__).resolve().parents[2]
AVALIACAO = RAIZ / "functions" / "base-conhecimento" / "avaliacao"

LARGURA, ALTURA = 1080, 2340
MARGEM = 36
LARGURA_BALAO = int(LARGURA * 0.74)
PREENCHIMENTO = 28

TEMAS = {
    "claro": {
        "fundo": (236, 229, 221),
        "barra": (0, 105, 92),
        "texto_barra": (255, 255, 255),
        "recebido": (255, 255, 255),
        "enviado": (217, 253, 211),
        "texto": (17, 27, 33),
        "hora": (102, 119, 129),
        "entrada": (255, 255, 255),
        "texto_entrada": (134, 150, 160),
    },
    "escuro": {
        "fundo": (11, 20, 26),
        "barra": (31, 44, 52),
        "texto_barra": (233, 237, 239),
        "recebido": (32, 44, 51),
        "enviado": (0, 92, 75),
        "texto": (233, 237, 239),
        "hora": (134, 150, 160),
        "entrada": (32, 44, 51),
        "texto_entrada": (134, 150, 160),
    },
}

# Contatos inventados. Números com DDD fictício e sem relação com pessoas reais.
CONTATOS = [
    "+55 11 98765-4321",
    "Atendimento",
    "+55 21 97654-3210",
    "Mãe",
    "+55 31 96543-2109",
    "Loja Ofertas",
    "+55 41 95432-1098",
    "Júlia",
]

# Resposta da própria pessoa: o que o filtro de mensagens recebidas deve tirar.
RESPOSTAS = [
    ("antes", "Oi, quem fala?"),
    ("depois", "Como assim? Não entendi"),
    ("depois", "Tá bom, vou ver aqui"),
    ("antes", "Boa tarde"),
    ("depois", "Sério? Me explica melhor"),
    ("depois", "Ok"),
]


def fonte(caminho, tamanho):
    return ImageFont.truetype(str(caminho), tamanho)


def quebrar(texto, f, largura, desenho):
    """Quebra o texto em linhas que cabem em `largura` pixels."""
    linhas, atual = [], ""
    for palavra in texto.split():
        tentativa = f"{atual} {palavra}".strip()
        if desenho.textlength(tentativa, font=f) <= largura:
            atual = tentativa
        else:
            if atual:
                linhas.append(atual)
            atual = palavra
    if atual:
        linhas.append(atual)
    return linhas


def baloes(texto):
    """Divide a mensagem em até 3 balões, nas fronteiras de frase."""
    frases = [f for f in re.split(r"(?<=[.!?])\s+", texto.strip()) if f]
    if len(frases) <= 1:
        return frases
    partes = min(3, len(frases))
    tamanho = -(-len(frases) // partes)
    return [" ".join(frases[i : i + tamanho]) for i in range(0, len(frases), tamanho)]


def desenhar(mensagem_textos, resposta, contato, tema, fontes, hora_base):
    cores = TEMAS[tema]
    img = Image.new("RGB", (LARGURA, ALTURA), cores["fundo"])
    d = ImageDraw.Draw(img)
    f_msg, f_hora, f_nome, f_status, f_simbolo = fontes

    # Barra de status e cabeçalho do contato.
    d.rectangle([0, 0, LARGURA, 250], fill=cores["barra"])
    d.text((MARGEM, 22), f"{hora_base[0]:02d}:{hora_base[1] + 9:02d}", font=f_status, fill=cores["texto_barra"])
    d.text((LARGURA - 190, 22), "87%", font=f_status, fill=cores["texto_barra"])
    d.text((MARGEM, 128), "<", font=f_nome, fill=cores["texto_barra"])
    d.ellipse([110, 110, 200, 200], fill=(170, 180, 186))
    d.text((230, 112), contato, font=f_nome, fill=cores["texto_barra"])
    d.text((230, 172), "online", font=f_status, fill=cores["texto_barra"])

    y = 300
    largura_chip = d.textlength("Hoje", font=f_hora) + 48
    d.rounded_rectangle(
        [(LARGURA - largura_chip) / 2, y, (LARGURA + largura_chip) / 2, y + 60],
        radius=16,
        fill=cores["recebido"],
    )
    d.text(((LARGURA - largura_chip) / 2 + 24, y + 10), "Hoje", font=f_hora, fill=cores["hora"])
    y += 110

    altura_linha = f_msg.size + 14
    minuto = hora_base[1]

    def balao(texto, enviado):
        nonlocal y, minuto
        linhas = quebrar(texto, f_msg, LARGURA_BALAO - 2 * PREENCHIMENTO, d)
        largura_texto = max(d.textlength(l, font=f_msg) for l in linhas)
        hora = f"{hora_base[0]:02d}:{minuto:02d}" + (" ✓✓" if enviado else "")
        largura_hora = d.textlength(hora, font=f_hora)
        largura = max(largura_texto, largura_hora) + 2 * PREENCHIMENTO
        altura = len(linhas) * altura_linha + f_hora.size + 2 * PREENCHIMENTO + 8
        x0 = LARGURA - MARGEM - largura if enviado else MARGEM
        d.rounded_rectangle(
            [x0, y, x0 + largura, y + altura],
            radius=22,
            fill=cores["enviado" if enviado else "recebido"],
        )
        for i, linha in enumerate(linhas):
            d.text((x0 + PREENCHIMENTO, y + PREENCHIMENTO + i * altura_linha), linha, font=f_msg, fill=cores["texto"])
        # Os tiques de leitura usam a fonte de símbolos: a de texto não os tem.
        texto_hora = hora.removesuffix(" ✓✓")
        x_hora = x0 + largura - PREENCHIMENTO - largura_hora
        y_hora = y + altura - PREENCHIMENTO - f_hora.size
        d.text((x_hora, y_hora), texto_hora, font=f_hora, fill=cores["hora"])
        if enviado:
            x_tique = x_hora + d.textlength(texto_hora + " ", font=f_hora)
            d.text((x_tique, y_hora), "✓✓", font=f_simbolo, fill=(83, 189, 235))
        y += altura + 22
        minuto = min(59, minuto + 1)

    momento, texto_resposta = resposta
    if momento == "antes":
        balao(texto_resposta, enviado=True)
    for texto in mensagem_textos:
        balao(texto, enviado=False)
    if momento == "depois":
        balao(texto_resposta, enviado=True)

    # Barra de digitação.
    d.rounded_rectangle([MARGEM, ALTURA - 150, LARGURA - 170, ALTURA - 40], radius=55, fill=cores["entrada"])
    d.text((MARGEM + 50, ALTURA - 122), "Mensagem", font=f_msg, fill=cores["texto_entrada"])
    d.ellipse([LARGURA - 150, ALTURA - 150, LARGURA - 40, ALTURA - 40], fill=(0, 168, 132))

    if y > ALTURA - 180:
        raise ValueError("conversa não coube na tela")
    return img


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--arquivo", default="teste.json")
    p.add_argument("--saida", default=str(RAIZ / "build" / "prints_sinteticos"))
    p.add_argument("--fonte", default="C:/Windows/Fonts/segoeui.ttf")
    p.add_argument("--simbolos", default="C:/Windows/Fonts/seguisym.ttf")
    args = p.parse_args()

    conjunto = json.loads((AVALIACAO / args.arquivo).read_text(encoding="utf-8"))
    saida = Path(args.saida)
    saida.mkdir(parents=True, exist_ok=True)
    fontes = (fonte(args.fonte, 44), fonte(args.fonte, 30), fonte(args.fonte, 48), fonte(args.fonte, 36), fonte(args.simbolos, 30))

    mensagens = [m["id"] for m in conjunto["golpes"]] + [m["id"] for m in conjunto["semGolpe"]]
    textos = {m["id"]: m["texto"] for m in conjunto["golpes"] + conjunto["semGolpe"]}
    indice = []
    for i, id_ in enumerate(mensagens):
        tema = "claro" if i % 2 == 0 else "escuro"
        img = desenhar(
            baloes(textos[id_]),
            RESPOSTAS[i % len(RESPOSTAS)],
            CONTATOS[i % len(CONTATOS)],
            tema,
            fontes,
            (9 + i % 12, 10 + (i * 7) % 40),
        )
        img.save(saida / f"{id_}.png")
        indice.append({"id": id_, "arquivo": f"{id_}.png", "tema": tema})
    (saida / "indice.json").write_text(json.dumps({"arquivo": args.arquivo, "prints": indice}, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"{len(indice)} prints em {saida}")


if __name__ == "__main__":
    main()
