#!/usr/bin/env python
"""Bangun job WordCraft untuk laporan Minggu 9.

Isi tiap langkah ada di ISI di bawah; build() menyalin template, mengisi tabel
wadah, lalu menulis job-laporan9.json yang dijalankan wordcraft-cli.
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

WEEK = os.path.dirname(os.path.abspath(__file__))
DOCX = os.path.join(WEEK, "Laporan Jobsheet Minggu 9 - Adam Bahy Maulana.docx")
PDF = DOCX[:-5] + ".pdf"
JOB = os.path.join(WEEK, "job-laporan9.json")
TPL = r"C:/Kuliah/Template Laporan Jobsheet - Rapi.docx"
SHOT = os.path.join(WEEK, "screenshots")

SECTIONS = ["Praktikum Ke-1", "Praktikum Ke-2", "Praktikum Ke-3", "Soal Praktikum"]
TBL_BLOCK = {"Praktikum Ke-1": 3, "Praktikum Ke-2": 5,
             "Praktikum Ke-3": 7, "Soal Praktikum": 9}
HEAD_BLOCK = {"Praktikum Ke-1": 2, "Praktikum Ke-2": 4,
              "Praktikum Ke-3": 6, "Soal Praktikum": 8}
JUDUL = {
    "Praktikum Ke-1": "Praktikum Ke-1 : Prompt dan context engineering",
    "Praktikum Ke-2": "Praktikum Ke-2 : Generate, verifikasi, dan pengujian",
    "Praktikum Ke-3": "Praktikum Ke-3 : Debug, refactor, dan explain",
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


def img(name, caption):
    path = os.path.join(SHOT, name)
    CUR.append({"k": "img", "path": path, "cap": caption, "w": _w_pt(path)})


def tbl(title, header, rows):
    CUR.append({"k": "tbl", "title": title, "header": list(header),
                "rows": [[str(v) for v in r] for r in rows]})


# ---------------------------------------------------------------- Praktikum 1
def p1_1():
    put("Prompt disusun dengan formula lima slot: peran, konteks, tugas, batas, "
        "dan bentuk keluaran. Setiap slot menutup satu jenis kesalahan yang "
        "berbeda, sehingga tidak ada slot yang boleh kosong.")
    code("""
Peran   : senior Flutter dev.
Konteks: project campus_notify, feature-first (presentation -> domain <- data),
          Riverpod, pengumuman diambil lewat repository. Versi package:
          flutter_riverpod 3.4.3, dio 5.11.1, go_router 18.0.2, Dart ^3.13.2.
          Kontrak yang ditempel: Announcement, AnnouncementRepository,
          GetAnnouncements, announcementsProvider.
Tugas   : tambah pencarian judul pengumuman + empty state.
Batas   : jangan ubah arsitektur, jangan panggil repository dari widget,
          maksimal 80 baris.
Output  : kode + 3 test case + cara uji.
""")
    tbl("Tabel 1. Fungsi tiap slot prompt", ["Slot", "Isi pada Minggu 9", "Kesalahan yang dicegah"], [
        ["Peran", "senior Flutter dev", "jawaban bergaya tutorial, bukan kode siap pakai"],
        ["Konteks", "struktur fitur, versi package, empat kontrak", "API dan jalur berkas yang tidak ada"],
        ["Tugas", "pencarian judul dan empty state", "fitur melebar ke pencarian isi dan filter tanggal"],
        ["Batas", "tanpa ubah arsitektur, tanpa repository di widget, 80 baris", "logika bisnis masuk ke presentation"],
        ["Output", "kode, tiga test, cara uji", "kode tanpa bukti jalan"],
    ])
    put("Slot konteks diisi dengan empat kontrak yang benar-benar dipakai fitur, "
        "bukan seluruh isi proyek. Cara ini menjaga prompt tetap pendek sekaligus "
        "memberi AI bentuk data yang tepat.")


def p1_2():
    put("Dua prompt diuji pada tugas yang sama untuk melihat pengaruh bentuk "
        "prompt terhadap hasil. Prompt pertama hanya menyebut keinginan, prompt "
        "kedua memakai formula lima slot.")
    code("""
Lemah:
  "buatkan fitur pencarian pengumuman di flutter"

Terbatas:
  Peran: senior Flutter dev.
  Konteks: campus_notify, Riverpod, entity Announcement(id, title, summary),
           AnnouncementRepository.fetch(), GetAnnouncements.call().
  Tugas: pencarian judul pengumuman + empty state.
  Batas: aturan filter tidak boleh di widget, maksimal 80 baris.
  Output: kode + 3 test + cara uji.
""")
    put("Prompt lemah menghasilkan fitur yang mencari di seluruh isi pengumuman "
        "dan menaruh filter langsung di widget. Prompt terbatas menghasilkan "
        "pencarian pada judul saja, walau aturan filternya masih diletakkan di "
        "provider presentasi sehingga perlu dipindahkan pada tahap refactor.")
    put("Batas jumlah baris terbukti berguna: keluaran yang dibatasi 80 baris "
        "mudah dibaca penuh sebelum ditempel, sehingga setiap import asing "
        "langsung terlihat.")


def p1_3():
    put("Konteks yang dikirim ke AI dibatasi pada empat kontrak dan daftar versi "
        "package. Isi berkas penyimpanan token, nilai token, dan sisa repository "
        "tidak pernah disertakan.")
    tbl("Tabel 2. Bahan yang dikirim dan yang ditahan", ["Bahan", "Dikirim", "Alasan"], [
        ["Entity Announcement", "ya", "bentuk data yang harus dipakai fitur"],
        ["Kontrak AnnouncementRepository", "ya", "batas lapisan data"],
        ["Use case GetAnnouncements", "ya", "pola pemanggilan yang sudah ada"],
        ["announcementsProvider", "ya", "sumber data di presentation"],
        ["Versi package pubspec", "ya", "mencegah API usang"],
        ["Isi token_store.dart dan nilai token", "tidak", "kredensial tidak boleh keluar perangkat"],
        ["Seluruh isi repository", "tidak", "tidak dibutuhkan dan menambah biaya konteks"],
    ])
    put("Bila AI membutuhkan bentuk berkas yang tidak dikirim, permintaan "
        "ditulis dengan placeholder, misalnya nama kelas dan tanda tangan "
        "metode, tanpa isi badan fungsi yang menyentuh kredensial.")


# ---------------------------------------------------------------- Praktikum 2
def p2_1():
    put("Satu fitur dihasilkan dari satu prompt, yaitu pencarian judul "
        "pengumuman beserta empty state. Generator dijalankan pada sesi AI "
        "terpisah yang hanya menerima teks prompt dan empat kontrak.")
    tbl("Tabel 3. Berkas keluaran generator", ["Berkas draf", "Isi", "Nasib akhir"], [
        ["1-announcement_search_provider.dart",
         "Notifier query + FutureProvider hasil filter", "diterima dengan refactor"],
        ["2-announcement_search_page.dart",
         "halaman ConsumerWidget dengan TextField dan empty state", "diterima dengan refactor"],
        ["3-announcement_search_test.dart",
         "dua test use case dan satu widget test", "ditolak, test ditulis ulang"],
    ])
    put("Keluaran mentah disimpan di docs/ai-draft/ sebelum diperbaiki, sehingga "
        "selisih antara usulan AI dan kode akhir dapat diperiksa kapan saja.")


def p2_2():
    put("Verifikasi dijalankan dalam enam langkah berurutan, dari membaca draf "
        "sampai uji di perangkat. Langkah mesin dijalankan pada salinan proyek "
        "yang berisi draf mentah, bukan pada kode yang sudah diperbaiki.")
    tbl("Tabel 4. Hasil verifikasi enam langkah", ["Langkah", "Hasil"], [
        ["1 Membaca draf penuh",
         "jalur berkas tidak cocok: domain/announcement.dart, domain/get_announcements.dart, "
         "data/announcement_repository_impl.dart, presentation/announcement_search_page.dart"],
        ["2 Memeriksa lapisan",
         "grep package:flutter, package:dio, dan sqflite di domain menghasilkan 0 baris"],
        ["3 Analyze draf mentah",
         "19 issue: 4 uri_does_not_exist, 3 undefined_identifier, 4 undefined_function, "
         "2 undefined_class, 3 non_type_as_type_argument, 2 nullable, 1 implements_non_class"],
        ["4 Analyze setelah perbaikan", "No issues found!"],
        ["5 Test",
         "4 test use case dan 4 widget test hijau, total suite 23 test lulus"],
        ["6 Uji manual perangkat",
         "query kosong, cocok, dan tidak cocok sesuai rancangan"],
    ])
    put("Langkah ketiga adalah bukti terkuat: seluruh keluaran analyzer disimpan "
        "di docs/analyze-ai-draft.txt, sehingga jumlah temuan dapat dihitung "
        "ulang tanpa menjalankan apa pun.")


def p2_3():
    put("Klaim generator yang gugur adalah pernyataan bahwa drafnya lolos "
        "analyze tanpa issue. Analyze pada draf mentah menghasilkan 19 issue, "
        "dengan rincian sebagai berikut.")
    code("""
$ flutter analyze lib test
  error - Undefined name 'announcementsProvider' -
    announcement_search.dart:14:33 - undefined_identifier
  error - The method 'where' can't be unconditionally invoked because the
    receiver can be 'null' - announcement_search.dart:17:16
  error - Target of URI doesn't exist:
    'package:campus_notify/features/announcements/domain/announcement.dart' -
    announcement_search_test.dart:2:8 - uri_does_not_exist
  error - Undefined class 'Failure' -
    announcement_search_test.dart:14:38 - undefined_class
19 issues found.
""")
    put("Empat issue pertama menunjukkan AI mengarang jalur berkas yang tidak ada "
        "di proyek. Dua issue berikutnya menunjukkan AI memakai kelas Failure dan "
        "provider announcementsProvider tanpa import, seolah keduanya tersedia "
        "global.")
    put("Perbaikan dilakukan dengan menyesuaikan import pada struktur nyata: "
        "Failure diambil dari core/failures.dart dan announcementsProvider dari "
        "announcement_providers.dart. Setelah perbaikan, analyze bersih.")


def p2_4():
    put("Test ditulis sebagai bukti perilaku, bukan pelengkap. Empat test use "
        "case menguji aturan filter tanpa Riverpod, empat widget test menguji "
        "tampilan hasil dan cabang error, dan satu test membuktikan bug state "
        "pada halaman yang dibuka ulang.")
    code("""
test('query diabaikan huruf besar dan spasi tepi', () {
  final items = [ann(id: 1, title: 'Beasiswa Semester Ganjil'),
                 ann(id: 2, title: 'Libur Semester')];
  final hasil = const SearchAnnouncements()(items, '  beasiswa ');
  expect(hasil.items.map((e) => e.id), [1]);
});
""")
    tbl("Tabel 5. Sebaran test pada suite", ["Berkas test", "Jumlah", "Yang dijamin"], [
        ["test/search_announcements_test.dart", "4", "aturan filter di domain, tanpa Riverpod"],
        ["test/announcement_search_page_test.dart", "4", "hasil tampil, empty state, cabang error"],
        ["test/announcement_search_persistence_test.dart", "1", "query tidak tertinggal saat halaman dibuka ulang"],
        ["test lama Minggu 7 dan 8", "14", "perilaku lama tidak berubah"],
    ])
    put("Angka 23 berasal dari keluaran flutter test pada suite penuh, yaitu "
        "14 test warisan ditambah 9 test baru.")


# ---------------------------------------------------------------- Praktikum 3
def p3_1():
    put("Debug dijalankan dengan menulis test yang gagal lebih dahulu, bukan "
        "dengan menebak penyebab. Test membuka halaman cari, mengisi query, "
        "menutup halaman, lalu membukanya kembali dan memeriksa isi kolom ketik.")
    code("""
00:02 +0 -1: query tidak tertinggal setelah halaman dibuka ulang [E]
  Test failed. See exception logs above.
  file:///.../test/announcement_search_persistence_test.dart line 60
00:02 +0 -1: Some tests failed.
""")
    put("Kegagalan itu membuktikan dua hal sekaligus: query tetap tersimpan di "
        "provider global, dan kolom ketik pada halaman baru selalu kosong "
        "sehingga daftar terfilter tampil untuk teks yang tidak ada di layar.")
    tbl("Tabel 6. Rantai penyebab dan perbaikannya", ["Penyebab", "Akibat", "Perbaikan"], [
        ["NotifierProvider tanpa autoDispose", "query hidup selama aplikasi berjalan",
         "NotifierProvider.autoDispose"],
        ["filteredAnnouncementsProvider memegang listener", "provider query tidak pernah dibuang",
         "autoDispose pada kedua provider di rantai"],
        ["TextField tanpa controller", "tampilan tidak mengikuti state",
         "TextEditingController diisi nilai query saat halaman dibangun"],
    ])
    put("Perbaikan pertama yang hanya menambahkan autoDispose pada provider query "
        "tidak cukup: test tetap merah karena provider turunan masih memegang "
        "listener. Kedua provider di rantai harus memakai autoDispose, dan "
        "controller perlu diisi ulang dari nilai query.")


def p3_2():
    put("Refactor memindahkan aturan filter dari provider presentasi ke use case "
        "domain, sehingga aturan bisnis dapat diuji tanpa Riverpod. Perpindahan "
        "lapisan diperiksa dengan grep, bukan dengan membaca ulang seluruh berkas.")
    tbl("Tabel 7. Letak aturan filter sebelum dan sesudah refactor", ["Objek", "Sebelum", "Sesudah"], [
        ["Tempat filter", "presentation/providers/announcement_search.dart baris 17",
         "domain/usecases/search_announcements.dart baris 12"],
        ["Kemunculan where( di provider presentasi", "1", "0"],
        ["Kemunculan where( di domain", "0", "1"],
        ["Ketergantungan domain pada Flutter", "0", "0"],
        ["Tipe hasil", "FutureProvider<List<Announcement>>",
         "Provider<AsyncValue<({List<Announcement> items, Failure? failure})>>"],
    ])
    code("""
$ grep -rn "where(" lib/features/announcements/presentation/providers/
(0 baris)
$ grep -rn "package:flutter" lib/features/announcements/domain/
(0 baris)
""")
    put("Tipe hasil diganti agar status loading dan error tidak hilang. "
        "FutureProvider membuang status antara, sedangkan AsyncValue menyimpannya "
        "sehingga widget tetap dapat membedakan memuat, gagal, dan berisi.")


def p3_3():
    put("Verifikasi akhir dijalankan pada proyek setelah refactor, dengan tiga "
        "perintah mesin yang sama seperti minggu sebelumnya.")
    code("""
$ dart format --output=none --set-exit-if-changed lib test
Formatted 32 files (0 changed) in 0.14 seconds.

$ flutter analyze
No issues found! (ran in 9.8s)

$ flutter test
00:10 +23: All tests passed!
""")
    put("Keluaran ketiga perintah disimpan di docs/verifikasi-mesin.txt dan "
        "dipakai sebagai sumber angka pada laporan ini. Suite berisi 23 test: "
        "14 warisan, 4 test use case, 4 widget test, dan 1 test pembukti bug.")
    put("Fitur dinyatakan selesai setelah tiga keadaan teruji di perangkat: "
        "query kosong menampilkan semua pengumuman, query cocok menyisakan satu "
        "hasil, dan query tanpa hasil menampilkan empty state beserta teks "
        "query yang diketik.")


# -------------------------------------------------------------- Soal Praktikum
def s_1():
    put("AI challenge dikerjakan dengan dua sesi AI terpisah: sesi generator "
        "menulis draf fitur, sesi reviewer memeriksa kode yang sudah diperbaiki "
        "tanpa melihat riwayat percakapan sebelumnya. Reviewer hanya menerima "
        "tiga berkas kode dan diminta memberi maksimal tiga temuan dengan level "
        "blocker atau saran.")
    tbl("Tabel 8. Temuan reviewer dan keputusannya",
        ["Temuan", "Level", "Keputusan", "Alasan teknis"], [
            ["Query global persisten, TextField tanpa controller, tampilan dan hasil tidak sinkron",
             "blocker", "diterima dan diperbaiki",
             "pengguna melihat daftar terfilter untuk teks yang tidak ada di layar"],
            ["Test widget tidak mengunci perilaku state query",
             "saran", "diterima dan diperbaiki",
             "siklus tutup dan buka halaman adalah sumber bug dan belum diuji"],
            ["searchAnnouncementsProvider dinilai indirection tanpa dependensi",
             "saran", "ditolak",
             "pola yang sama dipakai getAnnouncementsProvider; menghapusnya membuat dua gaya wiring dalam satu fitur"],
        ])
    put("Keputusan ditetapkan setelah setiap usulan diuji, bukan setelah dibaca. "
        "Temuan pertama dibuktikan dengan test merah yang gagal di baris 60 "
        "sebelum perbaikan, dan hijau setelah kedua provider di rantai memakai "
        "autoDispose.")
    put("Resep reviewer untuk temuan pertama ternyata belum lengkap. Reviewer "
        "hanya menandai provider query perlu autoDispose, padahal provider "
        "turunan masih memegang listener, sehingga provider query tidak pernah "
        "dibuang. Test pembukti tetap merah sampai provider turunan ikut diubah "
        "dan controller diisi ulang dari nilai query.")


def s_2():
    put("Aplikasi dibangun dari project campus_notify Minggu 8 dengan tambahan "
        "fitur pencarian judul. Bukti diambil dari perangkat Infinix X6851 "
        "beresolusi 1080 x 2436 piksel.")
    img("09-01-cari-kosong.png", "Gambar 1. Halaman cari sebelum query diisi")
    put("Dua pengumuman tampil saat kolom ketik masih kosong. Judul beranda juga "
        "menunjukkan jumlah pengumuman terbaru, sehingga daftar penuh dapat "
        "dibandingkan dengan hasil pencarian.")
    img("09-02-cari-cocok.png", "Gambar 2. Hasil pencarian kata beasiswa")
    put("Query beasiswa menyisakan satu hasil, yaitu pengumuman berjudul Beasiswa "
        "Semester Ganjil. Pencocokan dilakukan pada judul tanpa membedakan huruf "
        "besar dan kecil.")
    img("09-03-cari-tidak-cocok.png", "Gambar 3. Empty state untuk query tanpa hasil")
    put("Query zzz tidak cocok dengan judul mana pun, sehingga halaman "
        "menampilkan teks Tidak ada hasil untuk zzz. Teks query disalin ke dalam "
        "pesan agar pengguna tahu penyaring mana yang kosong.")


def s_3():
    sub("Refleksi 1 : Halusinasi yang terbukti dan cara membuktikannya")
    put("Halusinasi yang terbukti adalah jalur berkas fiktif: empat "
        "uri_does_not_exist, satu Failure tanpa import, dan satu provider tanpa "
        "import. Bukti diambil dari keluaran analyzer atas draf mentah yang "
        "disimpan sebagai berkas, bukan dari penilaian atas kode. Perbaikan "
        "dilakukan bertahap sampai analyzer bersih, dan setiap tahap dapat "
        "diperiksa ulang karena keluarannya tersimpan.")
    sub("Refleksi 2 : Prompt yang bekerja dan perbaikannya")
    put("Prompt yang paling membantu adalah versi lima slot dengan empat kontrak "
        "ditempel, karena keluarannya memakai bentuk record yang sama dengan "
        "domain. Perbaikan yang dilakukan setelah percobaan pertama adalah "
        "menyebut larangan memakai Riverpod di domain dan menuliskan nama berkas "
        "nyata, sebab versi pertama tetap menaruh filter di presentation.")
    sub("Refleksi 3 : Refactor yang dikerjakan")
    put("Refactor memindahkan aturan filter dari provider presentasi ke use case "
        "SearchAnnouncements, sehingga aturan itu dapat diuji tanpa Riverpod. "
        "Rantai provider dibuat autoDispose agar state pencarian tidak terbawa "
        "antar kunjungan halaman, dan kontroler kolom ketik diisi dari nilai "
        "query saat halaman dibangun. Perubahan ini membuat satu test baru "
        "berubah dari merah menjadi hijau.")
    sub("Refleksi 4 : Keputusan tersulit")
    put("Keputusan tersulit adalah menolak temuan ketiga reviewer. Secara prinsip "
        "kode paling sedikit, usulan menghapus searchAnnouncementsProvider "
        "benar, tetapi penerapannya membuat fitur ini memakai pola wiring yang "
        "berbeda dari GetAnnouncements. Biaya ketidakseragaman dinilai lebih "
        "besar daripada tiga baris yang dihemat, sehingga usulan ditolak dengan "
        "alasan yang dicatat di docs/ai-log.md.")


ISI = {
    "Praktikum Ke-1": [("1 : Formula lima slot", p1_1),
                       ("2 : Prompt lemah dan prompt terbatas", p1_2),
                       ("3 : Konteks tanpa kredensial", p1_3)],
    "Praktikum Ke-2": [("1 : Satu fitur dari satu prompt", p2_1),
                       ("2 : Verifikasi enam langkah", p2_2),
                       ("3 : Halusinasi dan buktinya", p2_3),
                       ("4 : Test sebagai bukti", p2_4)],
    "Praktikum Ke-3": [("1 : Debug dengan test merah", p3_1),
                       ("2 : Refactor ke lapisan yang benar", p3_2),
                       ("3 : Verifikasi akhir", p3_3)],
    "Soal Praktikum": [("Tugas 1 : AI challenge dan keputusannya", s_1),
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


def fill_table_ops(tb, row, ops_list):
    out = []
    paras = 1          # blok 0 = paragraf pertama sel
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
            # otomatis setelah tabel. DILARANG caret.set mundur ke judul:
            # insert.table di paragraf berisi teks menghasilkan tabel rusak.
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
                         pos={"story": "body", "path": [tb, row, 1, paras + 2],
                              "off": 0}))
            out.append(C("select.paragraph"))
            out.append(C("para.style", style=STYLE["Sel"]))
            paras += 2
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
            # caption 10 pt: 9 pt terlalu kecil di cetak (lihat ATURAN-LAPORAN.md)
            C("styles.modify", style=STYLE["Caption"], chr={"size": 10}),
            C("caret.set", pos=pos(0, 0, 2)),
            C("select.paragraph"),
            C("text.insert", text="PEMOB"),
            C("caret.set", pos=pos(0, 6, 2)),
            C("select.paragraph"),
            C("text.insert", text="9")]

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
            ops = fill_table_ops(tb, i, step["ops"])
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