"""Jalankan job WordCraft lewat salinan di scratch.

wordcraft-cli menolak menulis langsung ke docx laporan di folder minggu
("Access is denied"), jadi job dijalankan pada salinan scratch lalu hasilnya
disalin kembali (docx + pdf).

pakai: py runjob.py <job.json>
"""
import json
import os
import shutil
import subprocess
import sys
import zipfile
import xml.etree.ElementTree as ET

SCRATCH = r"C:/Users/adamb/AppData/Local/hermes/cache/scratch"
CLI = r"C:/Users/adamb/wordcraft/app/wordcraft-cli.exe"
W = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"
WADAH_GRID = [1000, 8628]      # Langkah | Jawaban/Deskripsi
CONTENT_MAX = 8412             # 8628 - 2 x 108 padding sel


def _set(el, tag, val):
    el.set(W + tag, str(val))


def _cell_width(tc, w):
    pr = tc.find(W + "tcPr")
    if pr is None:
        pr = ET.Element(W + "tcPr")
        tc.insert(0, pr)
    tcw = pr.find(W + "tcW")
    if tcw is None:
        tcw = ET.Element(W + "tcW")
        pr.insert(0, tcw)
    _set(tcw, "w", w)
    _set(tcw, "type", "dxa")


def fix_layout(path):
    """insert.table di dalam sel menyetarakan lebar SEL WADAH jadi 4819/4819
    dxa (harusnya 1000/8628), jadi tabel data 8412 dxa menembus garis sel.
    Kembalikan lebar wadah dan kunci tabel data ke 8412 dxa."""
    zin = zipfile.ZipFile(path)
    root = ET.fromstring(zin.read("word/document.xml"))
    body = root.find(W + "body")
    for tbl in body.findall(W + "tbl"):
        grid = [int(g.get(W + "w")) for g in tbl.find(W + "tblGrid")]
        if grid != WADAH_GRID:
            continue
        for tr in tbl.findall(W + "tr"):
            for ci, tc in enumerate(tr.findall(W + "tc")):
                _cell_width(tc, WADAH_GRID[ci])
                for nt in tc.findall(W + "tbl"):        # tabel data di dalam sel
                    each = CONTENT_MAX // len(nt.find(W + "tblGrid"))
                    for g in nt.find(W + "tblGrid"):
                        _set(g, "w", each)
                    pr = nt.find(W + "tblPr")
                    tw = pr.find(W + "tblW")
                    if tw is None:
                        tw = ET.SubElement(pr, W + "tblW")
                    _set(tw, "w", CONTENT_MAX)
                    _set(tw, "type", "dxa")
                    lay = pr.find(W + "tblLayout")
                    if lay is not None:
                        _set(lay, "type", "fixed")
                    for ntr in nt.findall(W + "tr"):
                        for ntc in ntr.findall(W + "tc"):
                            _cell_width(ntc, each)
    data = ET.tostring(root, encoding="UTF-8", xml_declaration=True)
    tmp = path + ".tmp"
    with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            zout.writestr(item, data if item.filename == "word/document.xml"
                          else zin.read(item.filename))
    zin.close()
    os.replace(tmp, path)

job_path = os.path.abspath(sys.argv[1])
job = json.load(open(job_path, encoding="utf-8"))
docx = job["file"]
work = os.path.join(SCRATCH, "run_" + os.path.basename(docx))
shutil.copy(docx, work)
pdf = os.path.splitext(docx)[0] + ".pdf"
job["file"] = work
job["save"] = [work, os.path.join(SCRATCH, "run_" + os.path.basename(pdf))]
tmp_job = os.path.join(SCRATCH, "run_job.json")
json.dump(job, open(tmp_job, "w", encoding="utf-8"), ensure_ascii=False)

r = subprocess.run([CLI, "run", "--script", tmp_job], capture_output=True, text=True)
if r.returncode != 0:
    sys.exit(r.stderr.strip() or r.stdout.strip())
fix_layout(work)
shutil.copy(work, docx)
shutil.copy(job["save"][1], pdf)
print("ok:", docx)
print("ok:", pdf)