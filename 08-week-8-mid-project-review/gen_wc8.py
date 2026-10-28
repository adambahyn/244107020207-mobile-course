#!/usr/bin/env python
"""Bangun job WordCraft untuk laporan Minggu 8.

Isi tiap langkah ada di ISI di bawah; build() menyalin template, mengisi tabel
wadah, lalu menulis job-laporan8.json yang dijalankan wordcraft-cli.
"""
import json
import os

WEEK = os.path.dirname(os.path.abspath(__file__))
DOCX = os.path.join(WEEK, "Laporan Jobsheet Minggu 8 - Adam Bahy Maulana.docx")
PDF = DOCX[:-5] + ".pdf"
JOB = os.path.join(WEEK, "job-laporan8.json")
TPL = r"C:/Kuliah/Template Laporan Jobsheet - Rapi.docx"
SHOT = os.path.join(WEEK, "screenshots")

SECTIONS = ["Praktikum Ke-1", "Praktikum Ke-2", "Praktikum Ke-3", "Soal Praktikum"]
TBL_BLOCK = {"Praktikum Ke-1": 3, "Praktikum Ke-2": 5,
             "Praktikum Ke-3": 7, "Soal Praktikum": 9}
HEAD_BLOCK = {"Praktikum Ke-1": 2, "Praktikum Ke-2": 4,
              "Praktikum Ke-3": 6, "Soal Praktikum": 8}
JUDUL = {
    "Praktikum Ke-1": "Praktikum Ke-1 : Hygiene branch dan commit",
    "Praktikum Ke-2": "Praktikum Ke-2 : PR dan peer review",
    "Praktikum Ke-3": "Praktikum Ke-3 : Static analysis dan mid review",
    "Soal Praktikum": "Soal Praktikum : AI challenge, tugas, dan refleksi",
}

CUR = []


def put(text):
    CUR.append({"k": "p", "s": "Laporan Isi", "t": text})


def sub(text):
    CUR.append({"k": "p", "s": "Laporan Subsoal", "t": text})


def code(text):
    for line in text.strip("\n").split("\n"):
        CUR.append({"k": "p", "s": "Laporan Kode", "t": line if line.strip() else " "})


def img(name, caption, width=414.0):
    CUR.append({"k": "img", "path": os.path.join(SHOT, name), "cap": caption,
                "w": width})


def tbl(title, header, rows):
    CUR.append({"k": "tbl", "title": title, "header": list(header),
                "rows": [[str(v) for v in r] for r in rows]})


# ---------------------------------------------------------------- Praktikum 1
def p1_1():
    put("Audit dijalankan pada repository portfolio yang sama dengan Minggu 7, "
        "bukan repository baru. Tiga perintah pembuka dipakai untuk melihat "
        "riwayat, daftar cabang, dan berkas yang belum terlacak.")
    code("""
git log --oneline -15
git branch -a
git status
""")
    put("Hasil audit menunjukkan empat masalah kebiasaan. Tabel berikut "
        "merangkum temuan beserta buktinya di riwayat Git.")
    tbl("Tabel 1. Temuan audit riwayat", ["Masalah", "Temuan", "Bukti"], [
        ["Pesan commit tidak bermakna", "Satu commit hanya berisi huruf p", "3046045 p"],
        ["Beberapa keputusan dalam satu commit",
         "Refactor, dokumen, dan pembangun laporan tergabung",
         "2363cd4 (3.411 baris, 3 tujuan)"],
        ["Subjek tanpa tipe konvensional", "Prefix Week 7: bukan tipe commit",
         "e1a149f, 046e317"],
        ["Berkas codelab terhapus tanpa catatan",
         "Folder Minggu 6 hilang dari disk dan tidak sengaja masuk staging",
         "selisih 1.539 baris penghapusan"],
    ])
    put("Temuan keempat sempat menghasilkan commit yang salah. Perintah git add "
        "-A pada satu folder ikut men-stage penghapusan berkas codelab Minggu 6. "
        "Commit dibatalkan dengan git reset, berkas dipulihkan lewat git "
        "checkout, lalu commit diulang dengan dua path eksplisit.")


def p1_2():
    put("Branch develop dibuat sekali dari main, lalu semua pekerjaan Minggu 8 "
        "berangkat dari sana. Setiap perubahan kecil memakai cabang sendiri.")
    code("""
git checkout main
git checkout -b develop
git push -u origin develop
git checkout develop
git checkout -b fix/mask-token-range
git add lib/core/format.dart test/core_format_test.dart
git commit -m "fix(core): maskToken tidak lagi RangeError untuk token < 12 karakter"
git push -u origin fix/mask-token-range
""")
    put("Pilihan git add dengan path eksplisit, bukan git add -A, adalah koreksi "
        "langsung dari temuan audit langkah sebelumnya. Satu commit memuat satu "
        "alasan berubah sehingga bisa di-revert tanpa menyentuh pekerjaan lain.")
    put("Setelah PR pertama dibuka, target default Pull Request diarahkan ke "
        "develop dan main berhenti menerima commit langsung.")


def p1_3():
    put("Tiga pesan commit lama ditulis ulang ke format konvensional. Kolom "
        "alasan menjelaskan mengapa bentuk baru lebih baik untuk reviewer.")
    tbl("Tabel 2. Pesan commit sebelum dan sesudah perbaikan",
        ["Sebelum", "Sesudah", "Alasan"], [
            ["p", "chore(week8): salin proyek Minggu 7 sebagai baseline review",
             "menyebut tipe, lingkup, dan isi perubahan"],
            ["Hapus gitignore dan AGENTS.md",
             "chore(repo): hapus .gitignore dan AGENTS.md dari pelacakan",
             "menjelaskan objek yang dihapus dan dampaknya"],
            ["Week 7: refactor campus_notify ke feature-first Clean Architecture "
             "(analyze bersih, 10 test, 3 grep nol) + docs AI challenge + builder laporan",
             "refactor(arch): pisahkan campus_notify ke feature-first, "
             "presentation -> domain <- data",
             "satu commit satu tujuan; bukti mesin pindah ke badan commit"],
        ])
    put("Bentuk baru mengikuti pola tipe(lingkup): kalimat perintah. Tipe yang "
        "dipakai pada Minggu 8 adalah fix, chore, dan refactor, sedangkan bukti "
        "pemeriksaan mesin diletakkan di badan commit agar subjek tetap pendek.")


# ---------------------------------------------------------------- Praktikum 2
def p2_1():
    put("Tiga Pull Request kecil dibuka dari cabang masing-masing menuju "
        "develop: PR #3, #4, dan #5. Tidak ada PR yang melebihi 300 baris perubahan.")
    tbl("Tabel 3. Daftar Pull Request Minggu 8",
        ["Cabang", "Masalah", "Ukuran"], [
            ["#3 fix/mask-token-range",
             "substring(0, 12) melempar RangeError untuk token pendek (issue #1)",
             "2 berkas, +8/-2"],
            ["#4 fix/announcement-loading-state",
             "deep link menampilkan teks belum tersedia saat data masih dimuat",
             "2 berkas, +95/-30"],
            ["#5 chore/ci-workflow",
             "tidak ada penjaga otomatis untuk PR kotor (issue #2)",
             "1 berkas, +20/-0"],
        ])
    put("Isi PR mengikuti urutan masalah, solusi, cara uji, lalu dampak. Contoh "
        "badan PR yang dipakai pada perbaikan maskToken:")
    code("""
## Masalah
maskToken('abc') -> RangeError (end): Invalid value: Not in inclusive range 0..3: 12
Dampak: HomePage._load() gagal mengisi panel status perangkat.

## Solusi
potong = min(length, 12); satu jalur keluar, tanpa dependensi baru.

## Cara uji
1. flutter analyze  -> No issues found!
2. flutter test     -> +11 All tests passed!
3. manual: panel Access token menampilkan mock-access-...

Closes #1
""")
    put("Judul PR memakai tipe dan lingkup yang sama dengan commit, sehingga "
        "riwayat commit dan daftar PR terbaca sebagai satu cerita.")


def p2_2():
    put("Review dijalankan dengan dua peran terpisah karena pekerjaan ini tidak "
        "melibatkan rekan tim. Penulis menyiapkan PR, lalu reviewer memeriksa "
        "dengan checkout terpisah dan menjalankan sendiri perintah uji sebelum "
        "memberi komentar. Lima temuan wajib terpenuhi seperti tabel berikut.")
    tbl("Tabel 4. Temuan review dan keputusannya",
        ["Kategori", "Temuan", "Level", "Keputusan"], [
            ["Kebenaran", "maskToken melempar RangeError untuk token < 12 karakter",
             "blocker", "diperbaiki di PR fix/mask-token-range"],
            ["Kebenaran", "deep link mengklaim data tidak ada selama loading",
             "blocker", "diperbaiki di PR fix/announcement-loading-state"],
            ["Arsitektur",
             "AnnouncementPage membaca daftar global, bukan use case per id",
             "saran", "dicatat sebagai issue paruh kedua"],
            ["Test", "hanya jalur bahagia diuji: token panjang, data tersedia",
             "blocker", "tiga widget test dan dua unit test ditambah"],
            ["Keterbacaan", "dua cabang if/else di maskToken kembar",
             "saran", "disatukan menjadi satu ekspresi"],
        ])
    put("Temuan arsitektur tidak dikerjakan pada PR review karena mengubah "
        "kontrak domain: dibutuhkan use case GetAnnouncementById agar halaman "
        "detail tidak bergantung pada daftar penuh. Perubahan itu masuk daftar "
        "kerja paruh kedua, bukan ditumpangkan pada PR perbaikan bug.")


def p2_3():
    put("Komentar review ditulis dengan pola observasi, dampak, usulan konkret. "
        "Bentuk ini membuat penulis bisa bertindak tanpa bertanya ulang.")
    code("""
Kurang:
  "maskToken rawan, perbaiki."

Baik:
  "maskToken memanggil substring(0, 12) tanpa cek panjang (observasi).
   Untuk token 3 karakter ini melempar RangeError sehingga panel status
   perangkat gagal terisi (dampak).
   Usul: potong = min(length, 12), dan tulis test token 3 karakter lebih
   dulu supaya terlihat merah (usulan)."
""")
    put("Setiap komentar menyebut berkas dan baris, menyertakan cara reproduksi, "
        "dan menunjuk perubahan yang diinginkan. Komentar yang hanya menyebut "
        "rasa tidak enak dibaca ditolak saat review, karena tidak bisa "
        "ditindaklanjuti.")


def p2_4():
    put("Siklus yang dijalankan: reviewer memberi request changes, penulis "
        "memperbaiki pada cabang yang sama, reviewer memeriksa ulang, lalu "
        "approve dan merge squash agar riwayat develop tetap satu commit per "
        "perubahan.")
    tbl("Tabel 5. Status tindak lanjut per PR",
        ["PR", "Komentar", "Tindak lanjut", "Status"], [
            ["#3 mask-token-range", "3", "test merah ditulis lebih dulu, kode disederhanakan",
             "merged"],
            ["#4 announcement-loading", "3", "state.when, messageOf, tiga widget test",
             "merged"],
            ["#5 ci-workflow", "2", "urutan format-analyze-test, working-directory",
             "merged"],
        ])
    put("Issue #1 dan #2 ditutup setelah merge, cabang dihapus, dan tautan PR "
        "dicatat di README. Tidak ada PR berstatus request changes yang "
        "di-merge.")


# ---------------------------------------------------------------- Praktikum 3
def p3_1():
    put("Tiga perintah mesin dijalankan pada folder campus_notify sebelum PR "
        "diminta review. Semuanya hijau.")
    code("""
flutter analyze
  No issues found! (ran in 27.3s)

dart format --output=none --set-exit-if-changed lib test
  Formatted 25 files (0 changed) in 0.27 seconds

flutter test
  +14 All tests passed!
""")
    put("Satu temuan analyze muncul saat mengerjakan PR kedua: import "
        "domain/entities/announcement.dart menjadi tidak terpakai setelah "
        "penyusunan ulang halaman. Import dihapus, bukan dibiarkan dengan "
        "abaikan komentar, agar warning tidak menumpuk.")
    tbl("Tabel 6. Jenis keluaran analyze dan tindakannya",
        ["Keluaran", "Arti", "Tindakan"], [
            ["unused_import", "import mati setelah refactor", "hapus"],
            ["prefer_const_constructors", "widget bisa const", "tambahkan const"],
            ["undefined_class", "tipe tidak dikenal analyzer", "perbaiki tipe, bukan menonaktifkan aturan"],
        ])


def p3_2():
    put("Penjaga otomatis dipasang di akar repository dengan working-directory "
        "menunjuk folder proyek Minggu 8, karena repository berisi banyak folder "
        "minggu.")
    code("""
name: ci
on: [pull_request]
jobs:
  verify:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: 08-week-8-mid-project-review/campus_notify
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable }
      - run: flutter pub get
      - run: dart format --output=none --set-exit-if-changed lib test
      - run: flutter analyze
      - run: flutter test
""")
    put("Urutan langkah dipilih dari yang paling murah: format, analyze, lalu "
        "test. PR yang menyisakan spasi berantakan gagal dalam hitungan detik "
        "tanpa menghabiskan menit runner untuk kompilasi.")


def p3_3():
    put("Kesiapan paruh semester dinilai dari fondasi, bukan jumlah fitur. "
        "Sembilan butir penilaian dipenuhi seluruhnya, dengan satu butir "
        "tambahan berupa utang teknis yang sengaja ditunda.")
    tbl("Tabel 7. Checklist kesiapan paruh semester",
        ["Butir", "Status", "Bukti"], [
            ["Struktur feature-first terbukti", "lulus", "tiga grep sterilitas kosong"],
            ["analyze bersih", "lulus", "No issues found!"],
            ["test hijau", "lulus", "+14 All tests passed!"],
            ["format rapi", "lulus", "25 berkas, 0 berubah"],
            ["PR kecil dan commit jelas", "lulus", "tiga PR, masing-masing < 300 baris"],
            ["README, screenshot, cara menjalankan", "lulus", "README.md + screenshots/"],
            ["Komentar review ditindaklanjuti", "lulus", "delapan komentar, semua tertutup"],
            ["Aplikasi identik akhir Minggu 7", "lulus", "screenshot perangkat"],
            ["CI menolak PR kotor", "lulus", ".github/workflows/ci.yml"],
        ])
    put("Tiga butir utang teknis dicatat terbuka: bootstrap FCM masih berada di "
        "HomePage, belum ada cache lokal, dan Failure masih dibungkus menjadi "
        "Exception di provider. Ketiganya masuk rencana paruh kedua karena "
        "menyentuh kontrak data, bukan sekadar tampilan.")


# -------------------------------------------------------------- Soal Praktikum
def s_1():
    put("Prompt yang dipakai mereview PR adalah prompt dari modul, dijalankan "
        "dua kali pada dua PR berbeda tanpa ringkasan berkas.")
    code("""
Review PR Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan 5 temuan teratas + level (blocker/saran)
+ alasan + usulan potongan kode perbaikan.
""")
    put("Setiap temuan diverifikasi dengan mesin sebelum diterapkan. Tabel "
        "berikut mencatat usulan, cara verifikasi, dan keputusan akhir.")
    tbl("Tabel 8. Usulan AI dan keputusan akhir",
        ["Usulan AI", "Verifikasi", "Keputusan"], [
            ["maskToken RangeError untuk token pendek",
             "test merah: RangeError (end): range 0..3: 12", "diterima"],
            ["deep link menampilkan teks cadangan saat loading",
             "widget test gagal pada kode lama", "diterima"],
            ["prefix Exception bocor ke UI pada messageOf",
             "test messageOf lulus sebelum PR apa pun", "ditolak: klaim salah"],
            ["tambahkan cache sqflite sekarang",
             "benar secara teknis, menambah dependensi", "ditolak: di luar lingkup"],
            ["pindahkan bootstrap FCM ke notifier",
             "tidak melanggar dependency rule", "ditunda: menyentuh lifecycle Firebase"],
        ])
    put("Dua temuan terbukti benar dan diperbaiki, satu ditolak karena klaimnya "
        "tidak bertahan saat dijalankan, satu ditolak karena lingkup, dan satu "
        "ditunda dengan alasan yang sama jelasnya.")


def s_2():
    put("Mini project yang dikerjakan adalah lanjutan kampus_notify Minggu 7, "
        "bukan proyek baru. Bukti aplikasi berjalan diambil dari perangkat "
        "Infinix X6851 dengan resolusi 1080 x 2436 piksel.")
    img("08-01-login.png", "Gambar 1. Halaman login setelah build Minggu 8", 240.0)
    put("Halaman login tetap sama seperti akhir Minggu 7. Tombol masuk memakai "
        "token tiruan dan menyimpannya di penyimpanan aman perangkat.")
    img("08-02-home.png", "Gambar 2. Daftar pengumuman dan panel status perangkat", 240.0)
    put("Panel status perangkat menampilkan access token terpotong, status FCM, "
        "dan hasil simulasi refresh 401. Token dipotong dua belas karakter "
        "pertama, termasuk untuk token pendek setelah perbaikan pada PR pertama.")
    img("08-03-detail.png", "Gambar 3. Halaman deep link /pengumuman/7", 240.0)
    put("Halaman deep link menampilkan isi pengumuman yang dipilih. Sebelum PR "
        "kedua, halaman ini sempat menampilkan teks belum tersedia karena data "
        "masih dimuat pada frame pertama.")


def s_3():
    sub("Refleksi 1 : LGTM buta dan approve yang bertanggung jawab")
    put("LGTM buta adalah persetujuan tanpa checkout, tanpa menjalankan uji, dan "
        "tanpa membaca jalur gagal. Approve yang bertanggung jawab menuntut "
        "reviewer mereproduksi masalah, menjalankan perintah mesin, dan menilai "
        "apakah perubahan menutup penyebabnya. Risikonya bagi tim bukan satu bug "
        "yang lolos, melainkan hilangnya fungsi review sebagai penjaga mutu: "
        "semua PR akan lolos dengan beban pembuktian yang sama.")
    sub("Refleksi 2 : Kapan request changes, kapan cukup saran")
    put("Request changes dipakai bila perubahan menyentuh kebenaran atau "
        "kontrak: crash, kehilangan data, pelanggaran dependency rule, atau test "
        "yang tidak menutup kasus gagal. Saran dipakai untuk keterbacaan, "
        "penamaan, dan penyusunan widget yang tidak mengubah perilaku. Pada "
        "Minggu 8, dua temuan kebenaran berstatus request changes, sedangkan "
        "temuan keterbacaan dan arsitektur berstatus saran.")
    sub("Refleksi 3 : Bagian review AI yang ditolak atau disederhanakan")
    put("Saran menambah cache sqflite ditolak karena menambah dependensi dan "
        "lapisan data baru, sementara paruh kedua baru akan menyentuh jaringan "
        "nyata. Klaim bahwa prefix Exception bocor ke UI ditolak karena "
        "messageOf sudah memotong prefix tersebut, dan test yang ada membuktikan "
        "itu. Saran memindahkan bootstrap FCM disederhanakan menjadi catatan "
        "utang teknis, tidak dikerjakan pada PR perbaikan bug.")
    sub("Refleksi 4 : Perbaikan konkret setelah review")
    put("Halaman deep link kini membedakan tiga keadaan: memuat, gagal, dan "
        "berisi. Dampaknya, pengumuman yang dibuka dari notifikasi tidak lagi "
        "menampilkan kalimat menyesatkan saat data belum siap, dan kegagalan "
        "jaringan tampil sebagai pesan, bukan sebagai data kosong. Bukti "
        "perubahan ada pada tiga widget test baru yang gagal pada kode lama.")


ISI = {
    "Praktikum Ke-1": [("1 : Audit riwayat", p1_1),
                       ("2 : Branch kerja yang benar", p1_2),
                       ("3 : Perbaikan pesan commit", p1_3)],
    "Praktikum Ke-2": [("1 : Membuka PR kecil", p2_1),
                       ("2 : Review dengan checklist", p2_2),
                       ("3 : Komentar yang dapat ditindaklanjuti", p2_3),
                       ("4 : Tindak lanjut dan merge", p2_4)],
    "Praktikum Ke-3": [("1 : Tiga perintah mesin", p3_1),
                       ("2 : Penjagaan otomatis lewat CI", p3_2),
                       ("3 : Penilaian kesiapan paruh semester", p3_3)],
    "Soal Praktikum": [("Tugas 1 : Prompt AI dan verifikasinya", s_1),
                       ("Tugas 2 : Aplikasi berjalan di perangkat", s_2),
                       ("Refleksi", s_3)],
}

STYLE = {"Isi": "Laporan Isi", "Kode": "Laporan Kode", "Caption": "Laporan Caption",
         "Tabel Judul": "Laporan Tabel Judul", "Sel": "Laporan Sel",
         "SelHeader": "Laporan SelHeader"}


def pos(tb, row, cell, off=0):
    return {"story": "body", "path": [tb, row, cell, 0], "off": off}


def C(command, **params):
    return {"command": command, "params": params} if params else {"command": command}


def fill_table_ops(ops_list):
    out = []
    for op in ops_list:
        k = op["k"]
        if k == "p":
            out.append(C("para.style", style=STYLE_ID[op["s"]]))
            out.append(C("text.insert", text=op["t"]))
            out.append(C("text.newParagraph"))
        elif k == "img":
            out.append(C("insert.picture", path=op["path"], width=op["w"]))
            out.append(C("text.newParagraph"))
            out.append(C("para.style", style=STYLE["Caption"]))
            out.append(C("text.insert", text=op["cap"]))
            out.append(C("text.newParagraph"))
        else:
            out.append(C("para.style", style=STYLE["Tabel Judul"]))
            out.append(C("text.insert", text=op["title"]))
            out.append(C("text.newParagraph"))
            ncol = len(op["header"])
            out.append(C("insert.table", rows=len(op["rows"]) + 1, cols=ncol))
            cells = [op["header"]] + op["rows"]
            total = sum(len(r) for r in cells)
            n = 0
            for ri, r in enumerate(cells):
                for v in r:
                    n += 1
                    out.append(C("para.style",
                                 style=STYLE["SelHeader"] if ri == 0 else STYLE["Sel"]))
                    out.append(C("text.insert", text=v))
                    if n < total:
                        out.append(C("text.tab"))
            out.append(C("table.selectTable"))
            out.append(C("table.autofit", mode="fixed"))
            out.append(C("table.columnWidth", width=420.6 / ncol))
            out.append(C("table.borders", kind="all", width=0.5, color="808080"))
    return out


STYLE_ID = {"Laporan Isi": "Laporan Isi", "Laporan Kode": "Laporan Kode",
            "Laporan Caption": "Laporan Caption",
            "Laporan Tabel Judul": "Laporan Tabel Judul",
            "Laporan Sel": "Laporan Sel", "Laporan SelHeader": "Laporan SelHeader",
            "Laporan Subsoal": "Laporan Subsoal"}


def build():
    data = {}
    for sec in SECTIONS:
        data[sec] = []
        for label, fn in ISI[sec]:
            del CUR[:]
            fn()
            data[sec].append({"label": label, "ops": list(CUR)})

    cmds = [C("file.setAuthor", name="Hermes via MCP"),
            C("caret.set", pos=pos(0, 0, 2)),
            C("select.paragraph"),
            C("text.insert", text="PEMOB"),
            C("caret.set", pos=pos(0, 6, 2)),
            C("select.paragraph"),
            C("text.insert", text="8")]

    for sec in SECTIONS:
        suffix = JUDUL[sec].split(" : ", 1)[1]
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
            ops = fill_table_ops(step["ops"])
            while ops and ops[-1]["command"] == "text.newParagraph":
                ops.pop()
            cmds.extend(ops)

    cmds.append(C("review.trackChanges", value=True))

    with open(TPL, "rb") as src, open(DOCX, "wb") as dst:
        dst.write(src.read())
    with open(JOB, "w", encoding="utf-8") as f:
        json.dump({"file": DOCX.replace("\\", "/"),
                   "commands": cmds, "save": [DOCX, PDF]}, f,
                  ensure_ascii=False, indent=1)
    print(f"perintah: {len(cmds)} -> {JOB}")


if __name__ == "__main__":
    build()