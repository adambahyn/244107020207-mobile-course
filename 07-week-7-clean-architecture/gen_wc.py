#!/usr/bin/env python
"""Susun job.json WordCraft untuk laporan minggu 7.

Isi jawaban diambil apa adanya dari isi_laporan7.py: fungsi put/code/img/tbl
diganti perekam, jadi tidak ada teks yang diketik ulang di sini.
"""
import json
import os

MAXW_CM, MAXH_CM = 14.83, 12.5    # batas isi sel & tinggi (celah halaman maks 12,5 cm)


def _ratio(path):
    """rasio lebar/tinggi PNG tanpa PIL (baca IHDR)."""
    with open(path, "rb") as f:
        head = f.read(26)
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        return 0.75
    w, h = struct.unpack(">II", head[16:24])
    return w / h


def _w_pt(path):
    ar = _ratio(path)
    return min(MAXW_CM, MAXH_CM * ar) * 28.3465
import struct

import isi_laporan7 as B

WEEK = os.path.dirname(os.path.abspath(__file__))
DOCX = os.path.join(WEEK, "Laporan Jobsheet Minggu 7 - Adam Bahy Maulana.docx")
PDF = DOCX[:-5] + ".pdf"
JOB = os.path.join(WEEK, "job-laporan7.json")

SECTIONS = ["Praktikum Ke-1", "Praktikum Ke-2", "Praktikum Ke-3", "Soal Praktikum"]
TBL_BLOCK = {"Praktikum Ke-1": 3, "Praktikum Ke-2": 5,
             "Praktikum Ke-3": 7, "Soal Praktikum": 9}
HEAD_BLOCK = {"Praktikum Ke-1": 2, "Praktikum Ke-2": 4,
              "Praktikum Ke-3": 6, "Soal Praktikum": 8}
STYLE = {"Isi": "Laporan Isi", "Kode": "Laporan Kode", "Caption": "Laporan Caption",
         "Tabel Judul": "Laporan Tabel Judul", "Sel": "Laporan Sel",
         "SelHeader": "Laporan SelHeader"}

CUR = []


def _num(t):
    return B._num(t, "Laporan Isi")


def put(cell, text, style="Laporan Isi"):
    CUR.append({"k": "p", "s": style, "t": _num(text)})


def para(cell, text, style="Laporan Isi"):
    CUR.append({"k": "p", "s": style, "t": _num(text)})


def code(cell, text):
    for line in text.strip("\n").split("\n"):
        CUR.append({"k": "p", "s": "Laporan Kode", "t": line if line.strip() else " "})


def img(cell, path, caption, width=14.6):
    CUR.append({"k": "img", "path": path, "cap": _num(caption),
                "w": _w_pt(path)})


def tbl(cell, title, header, rows):
    CUR.append({"k": "tbl", "title": _num(title), "header": list(header),
                "rows": [[_num(str(v)) for v in r] for r in rows]})


for name in ("put", "para", "code", "img", "tbl"):
    setattr(B, name, globals()[name])

STYLE_ID = {"Laporan Isi": "Laporan Isi", "Laporan Kode": "Laporan Kode",
            "Laporan Caption": "Laporan Caption", "Laporan Tabel Judul": "Laporan Tabel Judul",
            "Laporan Sel": "Laporan Sel", "Laporan SelHeader": "Laporan SelHeader"}


def pos(tb, row, cell, off=0):
    return {"story": "body", "path": [tb, row, cell, 0], "off": off}


def C(command, **params):
    return {"command": command, "params": params} if params else {"command": command}


def fill_table_ops(tb, row, ops_list):
    out = []
    paras = 1          # paragraf pertama sel sudah ada (blok 0)
    for op in ops_list:
        k = op["k"]
        if k == "p":
            out.append(C("para.style", style=STYLE_ID[op["s"]]))
            out.append(C("text.insert", text=op["t"]))
            out.append(C("text.newParagraph"))
            paras += 1
        elif k == "img":
            # paragraf gambar jangan mewarisi style Caption (spasi before/after
            # caption bikin celah kosong sebelum gambar)
            out.append(C("para.style", style=STYLE["Sel"]))
            out.append(C("insert.picture", path=op["path"], width=op["w"]))
            out.append(C("text.newParagraph"))
            out.append(C("para.style", style=STYLE["Caption"]))
            out.append(C("text.insert", text=op["cap"]))
            out.append(C("text.newParagraph"))
            paras += 2
        else:
            # blok paras = judul, paras+1 = tabel, paras+2 = paragraf kosong
            # otomatis sesudah tabel. DILARANG caret.set mundur ke judul:
            # insert.table di paragraf berisi teks menghasilkan tabel rusak.
            out.append(C("para.style", style=STYLE["Tabel Judul"]))
            out.append(C("text.insert", text=op["title"]))
            out.append(C("text.newParagraph"))
            paras += 1
            ncol = len(op["header"])
            out.append(C("insert.table", rows=len(op["rows"]) + 1, cols=ncol))
            cells = [op["header"]] + op["rows"]
            total = sum(len(r) for r in cells)
            n = 0
            for ri, r in enumerate(cells):
                for v in r:
                    n += 1
                    out.append(C("text.insert", text=v))
                    out.append(C("select.paragraph"))
                    out.append(C("para.style",
                                 style=STYLE["SelHeader"] if ri == 0 else STYLE["Sel"]))
                    if n < total:
                        out.append(C("text.tab"))
            out.append(C("table.selectTable"))
            out.append(C("table.autofit", mode="fixed"))
            out.append(C("table.columnWidth", width=420.6 / ncol))
            out.append(C("table.borders", kind="all", width=0.5, color="808080"))
            out.append(C("caret.set",
                         pos={"story": "body", "path": [tb, row, 1, paras + 1],
                              "off": 0}))
            out.append(C("select.paragraph"))
            out.append(C("para.style", style=STYLE["Sel"]))
            paras += 1
    return out


def build():
    figs = B.build_figures()
    data = {}
    for sec in SECTIONS:
        data[sec] = []
        for label, fn in B.ISI[sec]:
            del CUR[:]
            if fn is B.p3_4:
                fn(None, figs)
                figs = figs[len(figs):] + figs  # jaga urutan bila dipanggil lagi
            else:
                fn(None)
            data[sec].append({"label": label, "ops": list(CUR)})

    cmds = [C("file.setAuthor", name="Hermes via MCP"),
            # caption 10 pt: 9 pt terlalu kecil di cetak (lihat ATURAN-LAPORAN.md)
            C("styles.modify", style=STYLE["Caption"], chr={"size": 10}),
            C("caret.set", pos=pos(0, 0, 2)),
            C("select.paragraph"),
            C("text.insert", text="PEMOB"),
            C("caret.set", pos=pos(0, 6, 2)),
            C("select.paragraph"),
            C("text.insert", text="7")]

    for sec in SECTIONS:
        judul = B.JUDUL[sec]
        suffix = judul.split(" : ", 1)[1] if " : " in judul else ""
        if suffix:
            cmds.append(C("caret.set", pos={"story": "body",
                                            "path": [HEAD_BLOCK[sec]],
                                            "off": len(sec)}))
            cmds.append(C("text.insert", text=" : " + suffix))

    for sec in SECTIONS:
        tb = TBL_BLOCK[sec]
        steps = data[sec]
        kurang = len(steps) + 1 - 4
        for _ in range(max(0, kurang)):
            cmds.append(C("caret.set", pos=pos(tb, 3, 0)))
            cmds.append(C("table.insertRowBelow"))
        for i, step in enumerate(steps, start=1):
            cmds.append(C("caret.set", pos=pos(tb, i, 0)))
            cmds.append(C("select.paragraph"))
            cmds.append(C("para.style", style=STYLE["Sel"]))
            cmds.append(C("text.insert", text=step["label"]))
            cmds.append(C("caret.set", pos=pos(tb, i, 1)))
            cmds.append(C("select.paragraph"))
            ops = fill_table_ops(tb, i, step["ops"])
            while ops and ops[-1]["command"] == "text.newParagraph":
                ops.pop()
            cmds.extend(ops)

    cmds.append(C("review.trackChanges", value=True))

    TPL = r"C:/Kuliah/Template Laporan Jobsheet - Rapi.docx"
    with open(TPL, "rb") as src, open(DOCX, "wb") as dst:
        dst.write(src.read())
    with open(JOB, "w", encoding="utf-8") as f:
        json.dump({"file": DOCX.replace("\\", "/"),
                   "commands": cmds, "save": [DOCX, PDF]}, f, ensure_ascii=False, indent=1)
    print(f"perintah: {len(cmds)} -> {JOB}")


if __name__ == "__main__":
    build()